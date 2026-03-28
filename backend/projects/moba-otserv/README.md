# MOBA OTServ

**Division:** STUDIO
**Game Type:** OTSERV (modo MOBA)
**Engine:** Canary
**Language:** Lua/C++
**Status:** Em Desenvolvimento

## Description
Servidor OTServ com mecânicas completas de MOBA (Multiplayer Online Battle Arena).
Um projeto experimental e inovador que usa a engine Canary como base para criar
uma experiência de MOBA dentro do universo Tibia.

## Mecânicas MOBA Planejadas
- **Lanes:** 3 rotas (top, mid, bot) com torres defensivas
- **Heróis:** personagens com habilidades únicas por vocação customizada
- **Objetivos:** destruição da base inimiga (Nexus / Ancient)
- **Minions:** ondas automáticas de criaturas por lane
- **Jungle:** área central com criaturas neutras e buffs (buffs de mana/stamina)
- **Partidas:** sistema de matchmaking, placar e tempo de jogo

## Desafios Técnicos
- Sistema de torres com aggro e targeting por zona
- Wave spawning automático e sincronizado por lane
- Reinício de mapa entre partidas (reset de posições e estados)
- Sistema de heróis com cooldown de habilidades via Lua

## Time de Agentes
- **Carlos (CTO)** — arquitetura das mecânicas MOBA
- **Rafael (Lua Dev)** — sistema de heróis, torres, minions, lanes
- **Viktor (C++ Dev)** — modificações no engine para suporte MOBA
- **Sophia (QA)** — testes de balanceamento e bugs de mecânica
- **Thiago (Balancer)** — balanceamento de heróis e progressão de partida
- **Beatriz (Mapper)** — design do mapa MOBA (arena, lanes, jungle, bases)
- **Diego (Designer)** — identidade visual dos heróis e interface MOBA
