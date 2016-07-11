# Iota - Uma plataforma para gerenciamento de indicadores

O aplicativo é uma plataforma que permite a criação dos indicadores, com o objetivo de facilitar o compartilhamento dos dados para visualização, comparação e re-utilização deles através de padrões de tecnologias abertos.

Ele foi criado inicialmente para atender ao "Programa Cidades Sustentaveis" uma parceria da Rede Nossa São Paulo,
Instituto Ethos de Empresas e Responsabilidade Social e Rede Social Brasileira por Cidades Justas e Sustentáveis.

[Consulte o site do Iota!](http://eokoe.github.io/Iota/)


[![Build Status](https://secure.travis-ci.org/iotaorg/Iota-Polis.png?branch=master)](https://travis-ci.org/iotaorg/Iota-Polis)

---

Essas são as modificações principais no backend do Iota, no polis:

* As redes são ações
* Só existe 1 cidade, todo o resto são regiões.
* Não há mais nada de frontend, apenas backend aqui. Porem, os arquivos estaticos /static ainda são usados pelo Iota-Polis-Admin-Frontend
* Indicadores do tipo variado não são mais testados, embora provavlmente ainda funcionem.

Para fazer deploy/testes:
* siga os passos do TravisCI
* Rode o script polis-sql/cidades.sql e polis-sql/setup.sql (leia/altere o que achar necessario)
* rode o container github.com/iotaorg @ Iota-Polis-Admin-Frontend/docker/run-container.sh
* rode o container github.com/iotaorg @ polis-web/run-container.sh


![Resultado](http://i.imgur.com/uchOwGA.jpg)



