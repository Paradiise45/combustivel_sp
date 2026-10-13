-- 1. Função de segurança (Security Definer) que verifica rapidamente se quem está a chamar é um Admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
DECLARE
  user_role TEXT;
BEGIN
  -- Busca o role do usuário que está logado no momento
  SELECT role INTO user_role FROM public.profiles WHERE id = auth.uid();
  RETURN user_role = 'admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. Política de LEITURA: Qualquer pessoa logada pode ver todos os perfis (útil para ver nomes no mapa)
CREATE POLICY "Permitir leitura de todos os perfis" 
  ON public.profiles FOR SELECT 
  USING (auth.uid() IS NOT NULL);

-- 3. Política de ATUALIZAÇÃO: O utilizador só pode editar o próprio perfil, e NUNCA a coluna 'role'
CREATE POLICY "Utilizador só atualiza o próprio nome" 
  ON public.profiles FOR UPDATE 
  USING (auth.uid() = id)
  -- A regra CHECK garante que, se ele tentar enviar um UPDATE para 'role', o banco de dados rejeita se for diferente de 'user'
  -- (Como os admins já são admins, eles não precisam de se promover a eles mesmos pela app, fazem isso por SQL)
  WITH CHECK (
    auth.uid() = id 
    AND role = 'user' -- Força que, se a app tentar alterar o role, ele só pode gravar 'user'
  );

-- 4. Política de INSERÇÃO (Fallback de segurança)
CREATE POLICY "Apenas triggers inserem perfis" 
  ON public.profiles FOR INSERT 
  WITH CHECK (false); -- Ninguém pode inserir manualmente pela app, apenas o trigger de cadastro que criámos na Migração 001

-- 5. Os admins também podem atualizar os perfis, caso precisem corrigir algo via painel do app no futuro
CREATE POLICY "Admins podem atualizar qualquer perfil" 
  ON public.profiles FOR UPDATE 
  USING (public.is_admin());
