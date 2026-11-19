import Foundation
import CoreBluetooth

struct Encontrado: Identifiable, Hashable {
    let id: UUID
    var nome: String
    var rssi: Int
}

enum EstadoSlot: String {
    case vazio = "Nenhum cubo"
    case conectando = "Procurando o cubo…"
    case conectado = "Conectado"
}

struct SlotInfo {
    var id: UUID? = nil
    var nome: String = ""
    var estado: EstadoSlot = .vazio
    var bateria: Int? = nil
}

/// Conexão com até 2 cubos Giiker (i3 / i3S / Mi Smart) por Bluetooth LE.
final class BLE: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var ligado = false
    @Published var procurando = false
    @Published var encontrados: [Encontrado] = []
    @Published var slots: [SlotInfo] = [SlotInfo(), SlotInfo()]

    /// dados de estado do cubo (20 bytes)
    var aoReceber: ((Int, Data) -> Void)?
    /// conectou / desconectou (slot, conectado, id do cubo)
    var aoMudarConexao: ((Int, Bool, UUID?) -> Void)?

    private var central: CBCentralManager!
    private var perifericos: [UUID: CBPeripheral] = [:]
    private var escrita: [UUID: CBCharacteristic] = [:]
    private var pararBusca: DispatchWorkItem?

    private let servicoDados = CBUUID(string: "AADB")
    private let caracDados = CBUUID(string: "AADC")
    private let servicoRW = CBUUID(string: "AAAA")
    private let caracLer = CBUUID(string: "AAAB")
    private let caracEscrever = CBUUID(string: "AAAC")

    override init() {
        super.init()
        for i in 0..<2 {
            if let s = UserDefaults.standard.string(forKey: "cubo\(i)"), let id = UUID(uuidString: s) {
                slots[i].id = id
                slots[i].nome = UserDefaults.standard.string(forKey: "cuboNome\(i)") ?? "Cubo \(i + 1)"
                slots[i].estado = .conectando
            }
        }
        central = CBCentralManager(delegate: self, queue: nil)
    }

    private func slotDe(_ id: UUID) -> Int? {
        for i in 0..<2 where slots[i].id == id { return i }
        return nil
    }

    // MARK: - ações

    func procurar() {
        guard central.state == .poweredOn else { return }
        encontrados = []
        procurando = true
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        pararBusca?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.parar() }
        pararBusca = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: item)
    }

    func parar() {
        if central.isScanning { central.stopScan() }
        procurando = false
    }

    func escolher(_ e: Encontrado, slot: Int) {
        guard let p = perifericos[e.id] else { return }
        // se esse cubo estava no outro lugar, solta de lá
        for i in 0..<2 where i != slot && slots[i].id == e.id { esquecer(i) }
        if let antigo = slots[slot].id, antigo != e.id, let pa = perifericos[antigo] {
            central.cancelPeripheralConnection(pa)
        }
        slots[slot] = SlotInfo(id: e.id, nome: e.nome, estado: .conectando, bateria: nil)
        UserDefaults.standard.set(e.id.uuidString, forKey: "cubo\(slot)")
        UserDefaults.standard.set(e.nome, forKey: "cuboNome\(slot)")
        conectar(p)
    }

    func esquecer(_ slot: Int) {
        if let id = slots[slot].id, let p = perifericos[id] {
            slots[slot] = SlotInfo()
            central.cancelPeripheralConnection(p)
        } else {
            slots[slot] = SlotInfo()
        }
        UserDefaults.standard.removeObject(forKey: "cubo\(slot)")
        UserDefaults.standard.removeObject(forKey: "cuboNome\(slot)")
        aoMudarConexao?(slot, false, nil)
    }

    func pedirBateria() {
        for (id, c) in escrita {
            if let p = perifericos[id], p.state == .connected {
                p.writeValue(Data([0xB5]), for: c, type: .withResponse)
            }
        }
    }

    private func conectar(_ p: CBPeripheral) {
        perifericos[p.identifier] = p
        p.delegate = self
        // connect() não expira: assim que o cubo acordar, ele conecta sozinho
        central.connect(p, options: nil)
    }

    private func reconectarSalvos() {
        let ids = slots.compactMap { $0.id }
        guard !ids.isEmpty else { return }
        for p in central.retrievePeripherals(withIdentifiers: ids) {
            conectar(p)
        }
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        ligado = central.state == .poweredOn
        if ligado { reconectarSalvos() }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let nome = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? ""
        let ehCubo = nome.hasPrefix("Gi") || nome.hasPrefix("Mi Smart") || nome.hasPrefix("Hi-")
        guard ehCubo else { return }
        perifericos[peripheral.identifier] = peripheral
        if let i = encontrados.firstIndex(where: { $0.id == peripheral.identifier }) {
            encontrados[i].rssi = RSSI.intValue
        } else {
            encontrados.append(Encontrado(id: peripheral.identifier, nome: nome, rssi: RSSI.intValue))
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let s = slotDe(peripheral.identifier) else {
            central.cancelPeripheralConnection(peripheral)
            return
        }
        slots[s].estado = .conectado
        peripheral.delegate = self
        peripheral.discoverServices([servicoDados, servicoRW])
        aoMudarConexao?(s, true, peripheral.identifier)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if slotDe(peripheral.identifier) != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.conectar(peripheral) }
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        escrita[peripheral.identifier] = nil
        guard let s = slotDe(peripheral.identifier) else { return }
        slots[s].estado = .conectando
        slots[s].bateria = nil
        aoMudarConexao?(s, false, peripheral.identifier)
        conectar(peripheral)   // tenta de novo sozinho
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for s in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(nil, for: s)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for c in service.characteristics ?? [] {
            if c.uuid == caracDados {
                peripheral.setNotifyValue(true, for: c)
                peripheral.readValue(for: c)
            } else if c.uuid == caracLer {
                peripheral.setNotifyValue(true, for: c)
            } else if c.uuid == caracEscrever {
                escrita[peripheral.identifier] = c
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if peripheral.state == .connected {
                        peripheral.writeValue(Data([0xB5]), for: c, type: .withResponse)
                    }
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let s = slotDe(peripheral.identifier), let v = characteristic.value else { return }
        if characteristic.uuid == caracDados {
            aoReceber?(s, v)
        } else if characteristic.uuid == caracLer, v.count >= 2 {
            slots[s].bateria = Int(v[v.startIndex + 1])
        }
    }
}
