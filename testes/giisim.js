// Simulador de pacotes do Giiker (inverso de giikerParse), só para testes
const Cube = require('../CuboMagico/cube.txt');
function encode(state, lastMove, encrypt) {
  const fac = Cube.toFacelet(state);
  const gC = Cube._gC, gE = Cube._gE, F = Cube.FACES;
  const col = i => F.indexOf(fac[i]);
  const v = new Array(40).fill(0);
  const coMask = [-1, 1, -1, 1, 1, -1, 1, -1];
  for (let c = 0; c < 8; c++) {
    let found = false;
    for (let j = 0; j < 8 && !found; j++) for (let o = 0; o < 3 && !found; o++) {
      let ok = true;
      for (let n = 0; n < 3; n++) if (col(gC[c][(n + o) % 3]) != ~~(gC[j][n] / 9)) ok = false;
      if (ok) { found = true; v[c] = j + 1; for (let w = 0; w < 3; w++) if ((3 + w * coMask[c]) % 3 == o) { v[c + 8] = w; break; } }
    }
    if (!found) throw new Error('corner ' + c);
  }
  const eo = [];
  for (let e = 0; e < 12; e++) {
    let found = false;
    for (let j = 0; j < 12 && !found; j++) for (let o = 0; o < 2 && !found; o++) {
      let ok = true;
      for (let n = 0; n < 2; n++) if (col(gE[e][(n + o) % 2]) != ~~(gE[j][n] / 9)) ok = false;
      if (ok) { found = true; v[e + 16] = j + 1; eo[e] = o; }
    }
    if (!found) throw new Error('edge ' + e);
  }
  for (let i = 0; i < 3; i++) { let x = 0; for (let b = 0; b < 4; b++) if (eo[i * 4 + b]) x |= 8 >> b; v[28 + i] = x; }
  if (lastMove >= 0) { v[32] = "BDLURF".indexOf(F[~~(lastMove / 3)]) + 1; v[33] = [1, 2, 3][lastMove % 3]; }
  let bytes = [];
  for (let i = 0; i < 20; i++) bytes.push(v[2 * i] << 4 | v[2 * i + 1]);
  if (encrypt) {
    const k = 0x3a, k1 = k >> 4, k2 = k & 15;
    for (let i = 0; i < 18; i++) bytes[i] = (bytes[i] - Cube._key[i + k1] - Cube._key[i + k2]) & 0xff;
    bytes[18] = 0xa7; bytes[19] = k;
  }
  return bytes;
}
module.exports = { encode };
