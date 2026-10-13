-- 1. Tabela de Postos (Guarda os postos reais vindos do mapa)
CREATE TABLE public.stations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  osm_id TEXT UNIQUE NOT NULL, -- O ID do OpenStreetMap
  name TEXT NOT NULL,
  brand TEXT,
  address TEXT,
  lat DOUBLE PRECISION,
  lon DOUBLE PRECISION,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
ALTER TABLE public.stations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Postos são públicos para leitura" ON public.stations FOR SELECT USING (true);
-- Nota: A inserção será controlada depois por uma função do sistema, ninguém insere postos à mão.

-- 2. Tabela de Testes Químicos (Fatos e Matemática)
CREATE TABLE public.fuel_tests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id UUID REFERENCES public.stations(id),
  user_id UUID REFERENCES public.profiles(id),
  fuel_type TEXT NOT NULL, -- Ex: Gasolina C, Etanol
  method TEXT NOT NULL,    -- Ex: Proveta, Galão
  water_volume DOUBLE PRECISION, -- volume lido na proveta
  density DOUBLE PRECISION,      -- densidade g/cm³
  ethanol_percent DOUBLE PRECISION, -- Calculado pelo sistema
  conformity BOOLEAN,               -- Aprovado ou Fraude
  moderation_status TEXT DEFAULT 'pendente' CHECK (moderation_status IN ('pendente', 'aprovado', 'rejeitado')),
  rejection_reason TEXT,
  reviewed_by UUID REFERENCES public.profiles(id),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
ALTER TABLE public.fuel_tests ENABLE ROW LEVEL SECURITY;
-- Regras de quem vê o quê:
CREATE POLICY "Utilizadores veem os próprios testes" ON public.fuel_tests FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Público vê apenas testes aprovados" ON public.fuel_tests FOR SELECT USING (moderation_status = 'aprovado');
CREATE POLICY "Administradores veem tudo" ON public.fuel_tests FOR SELECT USING (public.is_admin());
-- Regras de inserção:
CREATE POLICY "Utilizador só insere testes pendentes em seu nome" ON public.fuel_tests FOR INSERT WITH CHECK (auth.uid() = user_id AND moderation_status = 'pendente');

-- 3. Tabela de Avaliações Subjetivas (Opiniões 1 a 5 estrelas)
CREATE TABLE public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id UUID REFERENCES public.stations(id),
  user_id UUID REFERENCES public.profiles(id),
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Avaliações são públicas" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "Utilizadores inserem próprias avaliações" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
