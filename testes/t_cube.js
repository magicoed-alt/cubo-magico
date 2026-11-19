const Cube = require('../CuboMagico/cube.txt'); const m = require('../CuboMagico/min2phase.txt'); const {encode} = require('./giisim.js');
let fails = 0; const ok = (c, msg) => { if (!c) { fails++; console.log('FALHA', msg); } };
const MV = []; for (let i=0;i<18;i++) MV.push(Cube.moveName(i));
for (let t=0;t<300;t++){
  const alg = Array.from({length: 25}, () => MV[Math.floor(Math.random()*18)]).join(' ');
  const cc = Cube.applyAlg(new Cube.CC(), Cube.parseAlg(alg));
  ok(Cube.toFacelet(cc) === m.fromScramble(alg), 'facelet vs min2phase '+alg);
  const back = Cube.fromFacelet(Cube.toFacelet(cc)); ok(back && Cube.equals(back, cc), 'roundtrip');
  ok(Cube.isSolved(Cube.mult(cc, Cube.inv(cc))) && Cube.isSolved(Cube.mult(Cube.inv(cc), cc)), 'inv');
  for (const enc of [false, true]) {
    const p = Cube.giikerParse(encode(cc, 5, enc)); ok(p && Cube.equals(p.state, cc), 'giiker '+enc); ok(p && p.lastMove===5, 'lastmove');
  }
  const last = Math.floor(Math.random()*18); const nxt = Cube.applyMove(cc, last);
  ok(Cube.findMove(cc, nxt) === last, 'findMove');
}
// solved packet from real Giiker (cstimer solved hex "12345678 00000000 123456789abc 000 ...")
const solvedHex = "1234567833333333123456789abc000041414141";
const raw = []; for (let i=0;i<20;i++) raw.push(parseInt(solvedHex.substr(2*i,2),16));
const p = Cube.giikerParse(raw); ok(p && Cube.isSolved(p.state), 'pacote resolvido real');
console.log('fails', fails, p && p.facelet);
process.exitCode = fails ? 1 : 0;
