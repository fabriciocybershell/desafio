FROM ubuntu

label Fabrício Caetano <fabricio47526245@gmail.com>

RUN mkdir /home/arch/
WORKDIR /home/arch/
ENV TZ=America/Sao_Paulo

COPY /desafio.sh /home/arch/

RUN																																\
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone														\
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' 	\
; yes | apt update																												\
; apt install -y curl postgresql																								\
; chmod +x /home/arch/desafio.sh

SHELL ["/bin/bash", "-c"]

CMD ./home/arch/desafio.sh