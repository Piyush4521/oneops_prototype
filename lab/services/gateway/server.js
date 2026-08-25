import express from 'express';
import { createProxyMiddleware } from 'http-proxy-middleware';
const app=express(); const port=9090; let active='green'; const counts=new Map();
const target=()=>active==='green'?process.env.GREEN_URL:process.env.BLUE_URL;
app.use((req,res,next)=>{const ip=req.ip||'unknown';const key=ip+req.path;const now=Date.now();const x=counts.get(key)||[];const recent=x.filter(t=>now-t<60000);const limit=req.path==='/login'?5:100;if(recent.length>=limit)return res.status(429).json({error:'rate limit exceeded'});recent.push(now);counts.set(key,recent);next()});
app.get('/__oneops/status',(req,res)=>res.json({active,rateLimit:'endpoint aware'}));
app.post('/__oneops/switch',(req,res)=>{active=active==='green'?'blue':'green';res.json({active});});
app.use(createProxyMiddleware({target:'http://127.0.0.1',router:()=>target(),changeOrigin:true}));
app.listen(port,()=>console.log('gateway listening on '+port));
