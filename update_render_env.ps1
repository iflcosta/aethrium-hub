$headers = @{"Authorization"="Bearer rnd_HzIKOT3HErcYsM61kGXqHGQmyWIr"; "Content-Type"="application/json"}
$body = @(
    @{"key"="FRONTEND_URL"; "value"="https://aethrium-hub.vercel.app"},
    @{"key"="N8N_URL"; "value"="https://iflopes.app.n8n.cloud"},
    @{"key"="DISCORD_WEBHOOK_URL"; "value"="https://discord.com/api/webhooks/1483471596994822164/TI1Rk460C0mjdG_ZX-sGvg6fUTb79v-9t0Cautcrocg120Ji1uPm5UpXeeJ1P6rSOQLc"},
    @{"key"="E2B_API_KEY"; "value"="e2b_405319b8d62944ffa9edc8e9f803397662659b8d"},
    @{"key"="PINECONE_INDEX"; "value"="aethrium-studio"},
    @{"key"="PINECONE_API_KEY"; "value"="pcsk_6RRYNf_QtQ91d5B1SEzGceHr5Pl2LABJESmYQewpyq53SR2oxq6R4ry5BZbRmG1EpT8eoc"},
    @{"key"="GOOGLE_API_KEY"; "value"="AIzaSyBcUtVlW2XpIPSfsVjx6NFEU9w9F239E6g"},
    @{"key"="DIRECT_URL"; "value"="postgresql://postgres.wpoqimsahieymjcrxgdj:ZpvY6GtvvQWUM5KT@aws-0-sa-east-1.pooler.supabase.com:5432/postgres?sslmode=require"},
    @{"key"="DATABASE_URL"; "value"="postgresql://postgres.wpoqimsahieymjcrxgdj:ZpvY6GtvvQWUM5KT@aws-0-sa-east-1.pooler.supabase.com:6543/postgres?sslmode=require&pgbouncer=true"}
) | ConvertTo-Json -Compress
Invoke-RestMethod -Method Put -Headers $headers -Uri "https://api.render.com/v1/services/srv-d6t0gv4hg0os73fgqih0/env-vars" -Body $body
