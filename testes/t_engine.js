const Cube = require('../CuboMagico/cube.txt'); const E = require('../CuboMagico/engine.txt'); const {encode} = require('./giisim.js');
let T = 1000000; const R = n => Math.floor(Math.random()*n);
const phys = [new Cube.CC(), new Cube.CC()];
const spoken = [];
function handle(a){ for (const x of JSON.parse(a)) { if (x.type==='speak') spoken.push(x.text); if (x.type==='cue') spoken.push('<bip>'); } }
function turn(k, m){ phys[k] = Cube.applyMove(phys[k], m); T += 300; handle(E.feed(k, encode(phys[k], m, k==1), T)); handle(E.tick(T)); }
function quarterTurns(m){ const f=~~(m/3)*3, p=m%3; if (p===0) return [f]; if (p===2) return [f+2]; return Math.random()<.5?[f,f]:[f+2,f+2]; }
function wait(ms){ const end=T+ms; while (T<end){ T+=200; handle(E.tick(T)); } }
function ui(){ return JSON.parse(E.ui()); }
E.config({steps: 1, optimizeMs: 300});
// conectar
handle(E.feed(0, encode(phys[0], -1), T)); handle(E.feed(1, encode(phys[1], -1, true), T));
let fails=0; const ok=(c,m)=>{ if(!c){fails++; console.log('FALHA',m);} };
const pat = JSON.parse(E.patterns());
function perform(stepCheck, mistakes){
  // performer: first move on chosen cube
  let guard=0;
  while (ui().run && ui().run.phase==='guide' && guard++<200) {
    const r = ui().run; const k=r.active; const n=r.next[0];
    let m = n.face*3+n.power;
    if (mistakes && Math.random()<0.08) m = R(18);
    for (const q of quarterTurns(m)) { turn(k,q); if (!ui().run || ui().run.phase!=='guide') break; }
  }
}
for (let trial=0; trial<15; trial++){
  const pl = trial%3===0 ? [{type:'match'},{type:'solve'}] : trial%3===1 ? [{type:'pattern', patternName:'Xadrez', facelet: pat[0].facelet},{type:'solve'}] : [{type:'match'},{type:'pattern',patternName:'Superflip',facelet:pat[1].facelet},{type:'solve'}];
  handle(E.cmd('start', {name:'t', steps: pl}, T));
  // espectadores misturam os dois
  for (let i=0;i<20;i++){ turn(0,R(18)); turn(1,R(18)); }
  ok(ui().run.phase==='wait', 'wait');
  wait(5200);
  ok(ui().run.phase==='armed', 'armed '+ui().run.phase);
  for (let s=0;s<pl.length;s++){
    const k = R(2);
    if (s>0) { wait(5200); }
    turn(k, R(18));
    const r = ui().run; ok(r.phase==='guide' || r.stepIndex>s, 'guide step '+s);
    ok(r.active===k, 'active');
    const len0 = r.total;
    perform(null, trial>=9);
    const st = pl[s];
    if (st.type==='match') ok(Cube.equals(phys[k], phys[1-k]), 'match ok');
    if (st.type==='solve') ok(Cube.isSolved(phys[k]), 'solve ok');
    if (st.type==='pattern') ok(Cube.toFacelet(phys[k])===st.facelet, 'pattern ok');
    if (trial<3) console.log('step', st.type, 'len', len0);
  }
  ok(ui().run.phase==='fim', 'fim');
}
console.log('fails', fails); console.log(spoken.slice(0,12).join(' | '));
// teste de repetição
handle(E.cmd('start',{steps:[{type:'solve'}]},T)); for(let i=0;i<10;i++) turn(0,R(18)); wait(5200); spoken.length=0; turn(0,R(18)); wait(7000); console.log('repeat:', spoken.join(' | '));
process.exitCode = fails ? 1 : 0;
