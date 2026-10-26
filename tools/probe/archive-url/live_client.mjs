import {createHash} from 'node:crypto';
const [B,...ps]=process.argv.slice(2);
for (const p of ps){ const r=await fetch(B+p,{redirect:'follow'}); const b=Buffer.from(await r.arrayBuffer());
 console.log('node',p,'final=',r.url,'status=',r.status,'redirected=',r.redirected,'ctype=',r.headers.get('content-type'),'sha16=',createHash('sha256').update(b).digest('hex').slice(0,16)); }
