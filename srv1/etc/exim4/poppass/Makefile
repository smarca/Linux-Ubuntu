BINDIR = /usr/sbin
FLAGS = -O2 -Wunused-result
CC=gcc


virdomadm: virdomadm.c Makefile
	@echo "*****************************************"
	@echo "* Instalar Bibliotecas (libpam-dev libmysqlclient-dev)"
	@echo "*****************************************"
	$(CC) $(CFLAGS) virdomadm.c -o virdomadm -ldl -lpam -lmysqlclient $(FLAGS)

install: virdomadm

finstall: virdomadm
	install -g bin -o root -m 500 virdomadm $(BINDIR)

clean:
	rm -f *.o *~* core Makefile.new Makefile.bak virdomadm

biblio:
	apt-get install libpam-dev
	apt-get install libmysqlclient-dev

