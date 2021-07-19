uilt-in#! /bin/bash

#-----------------------------------------------------------------------------------------------------------
#	DATA:				18 de julho de 2021;
#	SCRIPT:				desafio.sh;
#	VERSÃO:				0.0.1;
#	DESENVOLVIDO POR:		Fabrício Caetano;
#	GITHUB:				https://github.com/fabriciocaetano;
# 	CONTATO:			fabricio45726245@gmail.com;
# 	AMBIENTE:			ubuntu 20.04 LTS;
# 	IDE/EDITOR:			sublime text;
#
#	DESCRIÇÃO:			simples algoritmo para a realização do desafio da ARCH Tech,
#					que permite o cadastro, consulta e edição dos dados em um banco
#					de dados postgreSQL, seguido de um dockerfile para conteinerização
#					do mesmo;
#
#	DEPENDÊNCIAS:			curl, postgreSQL (rodando na rede localhost:5423, com usuário sem senha);
#
#	NOTAS:				Desenvolvido na linguagem Shell Script, utilizando o interpretador de 
#					comandos BASH e explorando ao máximo os recursos built-in do mesmo,
#					reduzindo o nível de dependências de pacotes externos, e 
#					compatibilidade com ambientes UNIX/linux.
#-----------------------------------------------------------------------------------------------------------

#/---------------------------------------------------------------------------\
#| regra para ele trabalhar com o postgrees: createuser -dws script	     |
#|									     |
#| para permitir o algoritmo usar sem necessidade de senha, já que parâmetro |
#| -w não esta funcionando em meus testes				     |
#|									     |
#| ALTER USER script PASSWORD '123456';					     |
#| configuração do pg_hba.conf:						     |
#| #"local" is for Unix domain socket connections only			     |
#| local   all             all               peer			     |
#| local   all             script            peer			     |
#\---------------------------------------------------------------------------/

[[ "${1}" = *"-h"* ]] && {
	echo "
SOBRE:	simples algoritmo para a realização do desafio da ARCH Tech,
        que permite o cadastro, consulta e edição dos dados em um banco
        de dados postgreSQL, seguido de um dockerfile para conteinerização
        do mesmo;
"
	exit
}

#variaveis de ambiente de controle:
#----------------------------------------------------------

#banco de dados
#usuario='script'
usuario='desafio'
address='localhost'
database='cliente'
port='5432'
tabelas=( 'clientes' 'telefones' 'emails' )
password='123456' # parâmetro -w e --nopassword desativados, não estão funcionando :/

printf -v elements '%s|' "${tabelas[@]}"

#----------------------------------------------------------

# meio de autenticação:
[[ -a .pgpass ]] || {
	#hostname:port:database:username:password
	#DOC: https://www.postgresql.org/docs/current/libpq-pgpass.html
	echo "${address}:${port}:${usuario}:${database}:${password}" > .pgpass
	chmod +0600 .pgpass	
}
PGPASSFILE=".pgpass"

#função de acesso:
querys(){
	resultado=$(psql -h ${address} -d ${database} -U ${usuario} -p ${port} <<< "${1}")
}

#verificar existência das tabelas necessárias:
querys "\d"
[[ "${resultado}" =~ (${tabelas%|}) ]] || {
	criado=1
	echo "tabela inexistente, criando tabelas" &
	querys "
	create table ${tabelas[0]}(id serial primary key, nome varchar(30) not null, cpf numeric not null,  rg numeric not null);
	create table ${tabelas[1]}(id serial primary key, ddd numeric not null, numero numeric not null);
	create table ${tabelas[2]}(id serial primary key, email varchar(30) not null);
	\d
	"

	[[ "${resultado}" =~ (${tabelas%|}) ]] && {
		echo "sucesso!"
	} || {
		echo -e "algum erro esta ocorrendo na criação do banco de dados, erro:\n ${resultado}"
		exit
	}
}

while :
do
	entrada=0
#perguntar quais opções são desejaveis
	echo "
[1] cadastro do cliente
[2] consultar clientes/dados
[3] edição de dados
[4] deletar tabela
[5] sair
"
	read -p "escolha a opção> " escolha_do_menu

	[[ "${escolha_do_menu}" = 5 ]] && {
		break
		clear
	}

#etapa de realização das ações escolhidas
	[[ "${escolha_do_menu}" = 1 ]] && {
		entrada=1
		#solicitação dos dados
		read -p "informe o Nome: " nome_do_cliente
		read -p "informe o Cpf: " cpf_do_cliente
		read -p "informe o Rg: " rg_do_cliente
		read -p "informe o telefone[já com o DDD]: " telefone_do_cliente
		read -p "informe o E-mail: " correio_eletronico_do_cliente

		while :
		do
			#processamento dos dados para serem incluídos no banco de dados
			# usando recursos built-in, sem grep, awk e afins
			[[ "${telefone_do_cliente// /}" =~ (\+[0-9]{2,3})?([0-9]{2})?([0-9]{9}) ]]
			DDD="${BASH_REMATCH[2]}"
			telefone="${BASH_REMATCH[3]}"
			[[ "${BASH_REMATCH[2]}" ]] && break || {
				read -p 'faltou o código de área: ' DDD
				[[ ${DDD} ]] && break
			}
		done

		# popular tabela clientes, telefones e emails
		querys "
		insert into clientes(nome, cpf, rg) values('${nome_do_cliente}', '${cpf_do_cliente}', '${rg_do_cliente}');
		insert into telefones(ddd, numero) values('${DDD}', '${telefone}');
		insert into emails(email) values('${correio_eletronico_do_cliente}');
		"
	}


	#pré request
	querys "\d"
	[[ "${escolha_do_menu}" = 2 ]] && {
		entrada=1
		#criar um menu com base nas tabelas do banco
		#e permitir ser selecionável

		num=0
		unset menu
		while IFS='|' read F1 F2 F3 F4;do
			[[ "${F2}" ]] &&  {
				menu[$num]="[$num]: ${F2// /}\n"
				selective[$num]="${F2// /}"
				num=$((num+1))
			}
		done <<< "${resultado}"

		echo -e " ${menu[@]}"
		read -p "selecione a tabela> " table_number
		echo -e "\nselecione a ação:\n[0]pesquisar\n[1]mostrar tudo"
		read -p "selecione o método> " metodo

		querys "SELECT * FROM ${selective[$table_number]};"

		[[ ${metodo} = 0 ]] && {
			read -p "informe o termo da busca(search):" busca
			echo "resultados:"

			#usando recursos built-in para pesquisa, sem grep, awk, e outras ferramentas
			while read linha;do
				[[ "${linha,,}" = *"${busca,,}"* ]] && {
					echo "${linha}"
				}
			done <<< ${resultado}
		}

		[[ ${metodo} = 1 ]] && {
			echo "${resultado}"
		}
	}

	[[ "${escolha_do_menu}" = 3 ]] && {
		entrada=1
		#criar um menu com base nas tabelas do banco
		#e permitir ser selecionável

		num=0
		unset menu
		while IFS='|' read F1 F2 F3 F4;do
			[[ "${F2}" ]] &&  {
				menu[$num]="[$num]: ${F2// /}\n"
				selective[$num]="${F2// /}"
				num=$((num+1))
			}
		done <<< "${resultado}"

		echo -e " ${menu[@]}"
		read -p "selecione a tabela> " table_number

		querys "SELECT * FROM ${selective[$table_number]};"
		echo -e "\ninforme o nome da coluna:\n${resultado}"
		read -p "nome da coluna> " coluna
		read -p "informe o numero da linha> " linha_id
		read -p "digite a nova informação> " info_select

		querys "
		UPDATE ${selective[$table_number]} SET ${coluna} = '${info_select}'
		WHERE id = ${linha_id};"
	}

	[[ "${escolha_do_menu}" = 4 ]] && {
		entrada=1

		num=0
		while IFS='|' read F1 F2 F3 F4;do
			[[ "${F2}" ]] &&  {
				menu[$num]="[$num] ${F2// /}\n"
				selective[$num]="${F2// /}"
				num=$((num+1))
			}
		done <<< "${resultado}"

		echo -e " ${menu[@]}"
		read -p "selecione a tabela> " table_number

		querys "DROP TABLE ${selective[$table_number]};"
	}

	[[ ${resultado} && ${entrada} = 0 ]] || echo "sucesso!"

	[[ "$entrada" ]] || echo "opção desconhecida!"
done
