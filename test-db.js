process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
const { Client } = require('pg');

async function testConnection(name, url) {
    console.log(`Testing ${name}...`);
    const client = new Client({ 
        connectionString: url,
        ssl: { rejectUnauthorized: false }
    });
    try {
        await client.connect();
        console.log(`✅ ${name} SUCCESS!`);
        await client.end();
        return true;
    } catch (err) {
        console.log(`❌ ${name} FAILED: ${err.message}`);
        return false;
    }
}

async function run() {
    const pass = 'ZpvY6GtvvQWUM5KT';
    const ref = 'wpoqimsahieymjcrxgdj';
    
    const variants = [
        { name: 'Direct (5432)', url: `postgresql://postgres:${pass}@db.${ref}.supabase.co:5432/postgres?sslmode=require` },
        { name: 'Pooler (6543)', url: `postgresql://postgres:${pass}@db.${ref}.supabase.co:6543/postgres?sslmode=require` }
    ];

    for (const v of variants) {
        await testConnection(v.name, v.url);
    }
}

run();
