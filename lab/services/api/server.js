import express from 'express';
const app=express(); const port=8080; const fail=process.env.FAIL_MODE==='1'; const color=process.env.APP_COLOR||'blue';
let requests=0, errors=0;
app.use((req,res,next)=>{requests++; next()});
app.get('/health',(req,res)=>{ if(fail){errors++; return res.status(503).json({status:'degraded',release:color,error:'dependency/configuration regression'});} res.json({status:'healthy',release:color});});
app.get('/api/data',(req,res)=>{if(fail){errors++; return res.status(500).json({error:'Cannot read properties of undefined (reading requestConfig)',release:color});} res.json({message:'request served',release:color,data:[1,2,3]});});
app.get('/metrics',(req,res)=>res.type('text').send(`oneops_requests_total ${requests}\noneops_errors_total ${errors}\noneops_release{release="${color}"} 1\n`));
app.listen(port,()=>console.log(`${color} listening on ${port}; fail=${fail}`));
