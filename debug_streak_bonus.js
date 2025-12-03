// ============================================================================
// DEBUG STREAK BONUS - Executar no Console do Navegador (F12)
// ============================================================================
// INSTRUÇÕES:
// 1. Abra o console do navegador (F12)
// 2. Copie e cole este código completo
// 3. Pressione Enter
// 4. O resultado mostrará EXATAMENTE onde está o problema
// ============================================================================

(async function debugStreakBonus() {
    console.log('🔍 Iniciando debug do sistema de bônus de streak...');
    
    try {
        // Verificar se está logado
        const { data: { user } } = await supabase.auth.getUser();
        
        if (!user) {
            console.error('❌ Usuário não está logado!');
            return;
        }
        
        console.log('✅ Usuário logado:', user.id);
        console.log('');
        
        // Chamar função de debug
        const { data, error } = await supabase.rpc('debug_streak_bonus', {
            p_user_id: user.id
        });
        
        if (error) {
            console.error('❌ Erro ao executar debug:', error);
            return;
        }
        
        console.log('📊 RESULTADO DO DEBUG:');
        console.log('═'.repeat(80));
        console.log('');
        
        // Exibir informações formatadas
        console.log('🎯 Streak atual:', data.current_streak, 'dias');
        console.log('🏆 Milestone detectado:', data.milestone, 'dias');
        console.log('📅 Período analisado:', data.days_back, 'dias');
        console.log('📈 Multiplicador:', data.multiplier);
        console.log('');
        console.log('💰 CÁLCULO DO BÔNUS:');
        console.log('   Pontos do período:', data.points_period);
        console.log('   Fórmula:', data.calculation);
        console.log('   Bônus calculado:', data.bonus_points, 'pontos');
        console.log('');
        console.log('✅ Já foi aplicado antes?', data.already_applied ? 'SIM' : 'NÃO');
        console.log('📝 Será inserido?', data.will_insert ? 'SIM ✅' : 'NÃO ❌');
        console.log('');
        
        if (!data.will_insert) {
            console.error('❌ MOTIVO PARA NÃO INSERIR:', data.reason_not_insert);
            console.log('');
            
            if (data.bonus_points <= 0) {
                console.error('🔍 PROBLEMA IDENTIFICADO:');
                console.error('   O bônus calculado é 0 ou negativo!');
                console.error('   Isso acontece porque:');
                console.error('   - Pontos do período:', data.points_period);
                console.error('   - Se pontos do período = 0, então bônus = 0');
                console.error('');
                console.error('💡 SOLUÇÃO:');
                console.error('   Verificar se você realmente tem pontos nos últimos', data.days_back, 'dias');
                console.error('   Execute no SQL Editor:');
                console.error('   SELECT * FROM points_history');
                console.error('   WHERE user_id = \'' + user.id + '\'');
                console.error('   AND created_at >= CURRENT_DATE - INTERVAL \'' + data.days_back + ' days\'');
                console.error('   AND action_type NOT IN (\'streak_bonus\', \'streak_bonus_retroactive\', \'streak_bonus_correction\')');
                console.error('   ORDER BY created_at DESC;');
            } else if (data.already_applied) {
                console.warn('⚠️ O bônus já foi aplicado anteriormente para este milestone');
            }
        } else {
            console.log('✅ TUDO OK! O bônus DEVERIA ser inserido.');
            console.log('   Se não foi inserido, o problema está na execução da função apply_streak_bonus_retroactive');
        }
        
        console.log('');
        console.log('═'.repeat(80));
        console.log('📋 Dados completos:', data);
        
    } catch (error) {
        console.error('❌ Erro no debug:', error);
    }
})();
