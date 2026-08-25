import assert from 'node:assert/strict';
const base='http://127.0.0.1:8787';
const post=async path=>{const r=await fetch(base+path,{method:'POST'});return {status:r.status,body:await r.json()}};
const inj=await post('/api/lab/inject-failure'); assert.equal(inj.status,200); assert.equal(inj.body.incident.status,'DETECTED');
const badVerify=await post('/api/incidents/verify-fix'); assert.equal(badVerify.status,409);
const inv=await post('/api/incidents/investigate'); assert.equal(inv.status,200); assert.equal(inv.body.incident.status,'INVESTIGATING');
const badApprove=await post('/api/incidents/approve-recover'); assert.equal(badApprove.status,409);
console.log('OneOps workflow guard tests passed.');
