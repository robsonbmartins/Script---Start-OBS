# Script---Start-OBS
# 🎬 OBS Workflow Automator

Automação em PowerShell para inicializar e encerrar o ecossistema do OBS Studio (Insta360, NVIDIA Broadcast e OBS) com um único clique, gerenciando dependências e liberando recursos automaticamente.

---

## 📖 Sobre o Projeto

**O Problema:** Configurar um ambiente de gravação ou transmissão complexo exige a abertura manual de múltiplos softwares em uma ordem estrita (ex: Inicializar câmera -> Aplicar filtros de IA -> Abrir o software de transmissão). Além de ser um processo tedioso, esquecer de fechar os aplicativos de suporte após o uso mantém recursos valiosos de CPU e RAM ocupados.

**A Solução:**
Este projeto fornece um fluxo de trabalho (workflow) de "um clique" (One-Click Start) para criadores de conteúdo e streamers. Através de um script inteligente, o sistema inicializa os drivers e softwares de câmera (Insta360), passa pelo processamento de IA (NVIDIA Broadcast) e, por fim, abre o OBS Studio. 

Enquanto você foca na sua produção, o script roda de forma completamente invisível (minimizado) em segundo plano, apenas monitorando a sessão. Assim que você encerra o OBS Studio, o script executa uma rotina de limpeza (*teardown*), fechando automaticamente todas as aplicações periféricas e liberando o hardware. Tudo encapsulado em um atalho idêntico ao nativo do OBS, pronto para ser fixado na barra de tarefas.

---

## ⚙️ Como Funciona / Arquitetura

O diretório contém a lógica de automação dividida entre o script de execução e o acionador do sistema operacional:

* **Linguagem Core:** PowerShell (`.ps1`).
* **Comportamento de Execução:** O script principal (`Iniciar_Fluxo_OBS.ps1`) é acionado através de um atalho do Windows (`.lnk`) customizado.
* **Parâmetros de Lançamento:** O atalho invoca o executável do PowerShell com os argumentos `-ExecutionPolicy Bypass` (para garantir a execução local sem bloqueios de política padrão) e `-WindowStyle Minimized` (suprimindo a janela do console para o usuário final).
* **Mapeamento Visual:** O atalho herda o ícone oficial do executável do OBS (`obs64.exe, 0`), permitindo uma integração limpa e nativa na interface do Windows (Barra de Tarefas / Menu Iniciar).
* **Ciclo de Vida do Script:**
    1.  **Startup Sequence:** Inicializa os processos dependentes em ordem cronológica (Insta360 > NVIDIA Broadcast > OBS Studio).
    2.  **Listener Mode:** O script entra em estado de suspensão inteligente, monitorando ativamente o processo principal (`obs64.exe`).
    3.  **Teardown Routine:** A detecção do encerramento do processo do OBS atua como um gatilho para comandos de `kill` ou encerramento gracioso dos processos secundários, prevenindo o consumo desnecessário em background.

---

## 🛠️ Pré-requisitos

Para que este script funcione corretamente, você precisa ter os seguintes softwares instalados no seu Windows:
* [OBS Studio](https://obsproject.com/pt-br)
* [NVIDIA Broadcast](https://www.nvidia.com/pt-br/geforce/broadcasting/broadcast-app/)
* Software da Insta360 (Link ou versão específica que você utiliza)
* Windows PowerShell (Nativo do Windows 10/11)

---

## 🚀 Instalação e Configuração

1. **Clone o repositório** ou baixe os arquivos para a sua máquina:
   ```bash
   git clone [https://github.com/SEU-USUARIO/SEU-REPOSITORIO.git](https://github.com/SEU-USUARIO/SEU-REPOSITORIO.git)
