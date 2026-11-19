// Mágico de olhos fechados: segura o cubo numa orientação qualquer e só segue as falas (posição)
const Cube = require('../CuboMagico/cube.txt'); const E = require('../CuboMagico/engine.txt'); const {encode} = require('./giisim.js');
const VEC = [[0,1,0],[1,0,0],[0,0,1],[0,-1,0],[-1,0,0],[0,0,-1]];
const cross=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
const same=(a,b)=>a[0]==b[0]&&a[1]==b[1]&&a[2]==b[2]; const neg=a=>a.map(x=>-x);
const R = n => Math.floor(Math.random()*n);
let T = 1e6, fails = 0; const ok=(c,m)=>{ if(!c){fails++; console.log('FALHA',m);} };
const phys=[new Cube.CC(), new Cube.CC()]; let falas=[];
function handle(a){ for (const x of JSON.parse(a)) if (x.type==='speak') falas.push(x.text); }
function turn(k,m){ phys[k]=Cube.applyMove(phys[k],m); T+=300; handle(E.feed(k,encode(phys[k],m),T)); handle(E.tick(T)); }
function wait(ms){ const e=T+ms; while(T<e){ T+=200; handle(E.tick(T)); } }
const ui=()=>JSON.parse(E.ui());
const LANG = process.argv[2] || 'pt';   // node t_cego.js en  → inglês com inversões (padrão CubeSmith)
if (LANG==='en') E.config({optimizeMs: 200, language:'en', faceNames:['top','right','front','bottom','left','back'],
  wordCW:'forward', wordHalf:'double', wordCCW:'reverse', invertLeft:true, invertBottom:true, invertBack:true});
else E.config({optimizeMs: 200});  // padrões: posição + orientação automática + 7 s
handle(E.feed(0,encode(phys[0],-1),T)); handle(E.feed(1,encode(phys[1],-1),T));
const NOMES=LANG==='en'?['top','right','front','bottom','left','back']:['cima','direita','frente','baixo','esquerda','trás'];
const DIR=LANG==='en'?{forward:0,double:1,reverse:2}:{frente:0,duplo:1,reverso:2};
const INV=LANG==='en'?[false,false,false,true,true,true]:[false,false,false,false,false,false];
const PRIMEIRA=LANG==='en'?'top forward':'cima frente';
function mago(k, top, right, erros){
  const up=VEC[top], rt=VEC[right], fr=cross(rt,up);
  const posVec=[up, rt, fr, neg(up), neg(rt), neg(fr)];
  let guard=0, lidas=0;
  while (guard++ < 300) {
    const r=ui().run; if(!r || !['armed','orient1','orient2','guide'].includes(r.phase)) break;
    if (falas.length===lidas) { wait(3300); if (falas.length===lidas) break; }  // espera a repetição
    let txt=falas[falas.length-1]; lidas=falas.length;
    txt=txt.replace(/^(corrige|não|correction|no), /,'').replace(/^(agora gire|now turn) /,'');
    const [nome, dir]=txt.split(' ');
    const pi=NOMES.indexOf(nome); ok(pi>=0 && dir in DIR, 'fala estranha: '+txt);
    const face=VEC.findIndex(v=>same(v,posVec[pi]));
    let d=DIR[dir]; if (INV[pi] && d!==1) d=2-d;
    let m=face*3+d;
    if (r.phase==='orient2' && erros && Math.random()<0.3) m=top*3;   // errou: girou cima de novo
    if (erros && r.phase==='guide' && Math.random()<0.1) m=R(18);
    const qs = m%3===1 ? (Math.random()<.5?[m-1,m-1]:[m+1,m+1]) : [m];
    for (const q of qs) turn(k,q);
  }
}
for (let trial=0; trial<20; trial++){
  const pl = trial%2 ? [{type:'match'},{type:'solve'}] : [{type:'solve'}];
  handle(E.cmd('start',{steps:pl},T));
  for(let i=0;i<20;i++){ turn(0,R(18)); turn(1,R(18)); }
  wait(6500); ok(ui().run.phase==='wait','ainda esperando aos 6,5 s');
  wait(800); ok(ui().run.phase==='armed','armado aos 7 s');
  ok(falas[falas.length-1]===PRIMEIRA, 'primeira fala: '+falas[falas.length-1]);
  for (let s=0;s<pl.length;s++){
    if (s>0) { wait(7300); }
    const k=R(2); let top=R(6), right; do { right=R(6);} while(right%3===top%3);
    // às vezes ele erra a "direita" girando cima/baixo
    mago(k, top, right, trial>=10);
    if (pl[s].type==='match') ok(Cube.equals(phys[k],phys[1-k]),'igualou');
    else ok(Cube.isSolved(phys[k]),'resolveu');
  }
  ok(ui().run.phase==='fim','fim '+ui().run.phase);
  if (trial<2) console.log(falas.slice(-8).join(' | '));
}
console.log('fails', fails); process.exitCode = fails?1:0;
