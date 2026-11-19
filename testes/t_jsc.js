// Simula o JavaScriptCore: scripts soltos num contexto sem module/require, chamadas pelas funções E_*
const vm = require('vm'), fs = require('fs'); const {encode} = require('./giisim.js'); const Cube = require('../CuboMagico/cube.txt');
const ctx = vm.createContext({ Date, Math, JSON, console });
for (const f of ['min2phase','cube','engine']) vm.runInContext(fs.readFileSync('../CuboMagico/'+f+'.txt','utf8'), ctx, {filename:f});
const call = (fn, ...a) => ctx[fn](...a);
console.log(call('E_init')); call('E_config', JSON.stringify({steps:2, optimizeMs: 200, velocidadeVoz: 1.2}));
const hex = b => b.map(x=>x.toString(16).padStart(2,'0')).join('');
let st = new Cube.CC(); let t = 1e6;
console.log(call('E_feed', 0, hex(encode(st,-1,true)), t));
call('E_cmd','start', JSON.stringify({name:'x', steps:[{type:'solve',patternName:'',facelet:''}]}), t);
for (let i=0;i<15;i++){ const m=Math.floor(Math.random()*18); st=Cube.applyMove(st,m); t+=200; call('E_feed',0,hex(encode(st,m,true)),t); }
t+=6000; console.log('tick', call('E_tick', t));
st=Cube.applyMove(st,0); t+=200; console.log('first move ->', call('E_feed',0,hex(encode(st,0,true)),t));
const ui = JSON.parse(call('E_ui')); console.log(ui.run.phaseLabel, ui.run.total, ui.run.next.slice(0,3).map(x=>x.label));
console.log(call('E_cmd','tap','{}',t+100));
console.log(JSON.parse(call('E_patterns')).length, 'padrões');
