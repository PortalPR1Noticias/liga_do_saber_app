-- Liga do Saber - domínio dos logins das crianças.
-- Execute depois da 0016_seguranca_limites.sql no Supabase SQL Editor.
--
-- Os logins das crianças (Edge Function `contas-liga`, migration 0014)
-- usavam e-mails internos `<usuario>@crianca.ligadosaber.app`, um domínio
-- que não é da GPLABS: o dono dele poderia pedir "esqueci a senha" e trocar
-- a senha da criança. Agora o domínio é `crianca.gpmkt.art.br`. Este
-- arquivo passa os logins já criados para o domínio novo; o usuário e a
-- senha da criança continuam os mesmos. Pode rodar mais de uma vez.

update auth.users
set email = replace(email, '@crianca.ligadosaber.app', '@crianca.gpmkt.art.br'),
    updated_at = now()
where email like '%@crianca.ligadosaber.app';

update auth.identities
set identity_data = jsonb_set(
      identity_data,
      '{email}',
      to_jsonb(replace(identity_data->>'email', '@crianca.ligadosaber.app', '@crianca.gpmkt.art.br'))
    ),
    updated_at = now()
where provider = 'email'
  and identity_data->>'email' like '%@crianca.ligadosaber.app';
