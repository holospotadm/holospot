const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error('❌ Variáveis de ambiente não encontradas!');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function applyMigration() {
    console.log('📝 Aplicando migration: fix_community_posts_isolation.sql');
    
    const sql = fs.readFileSync('./sql/migrations/20241029_fix_community_posts_isolation.sql', 'utf8');
    
    try {
        const { data, error } = await supabase.rpc('exec_sql', { sql_query: sql });
        
        if (error) {
            console.error('❌ Erro ao aplicar migration:', error);
            process.exit(1);
        }
        
        console.log('✅ Migration aplicada com sucesso!');
        console.log('📊 Resultado:', data);
        
    } catch (err) {
        console.error('❌ Erro:', err);
        process.exit(1);
    }
}

applyMigration();

