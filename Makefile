# See LICENSE file for license and copyright information

include config.mk

PROJECT  = jumanji
SOURCE   = $(shell find . -iname "*.c" -a ! -iname "database-*")
OBJECTS  = $(patsubst %.c, %.o,  $(SOURCE))
DOBJECTS = $(patsubst %.c, %.do, $(SOURCE))

ifeq (${DATABASE}, sqlite)
INCS   += $(SQLITE_INC)
LIBS   += $(SQLITE_LIB)
SOURCE += database-sqlite.c
else
ifeq (${DATABASE}, plain)
SOURCE += database-plain.c
endif
endif

all: options ${PROJECT}

options:
	@echo ${PROJECT} build options:
	@echo "CFLAGS  = ${CFLAGS}"
	@echo "LIBS    = ${LIBS}"
	@echo "DFLAGS  = ${DFLAGS}"
	@echo "CC      = ${CC}"

%.o: %.c
	@echo CC $<
	@mkdir -p .depend
	@${CC} -c ${CFLAGS} -o $@ $< -MMD -MF .depend/$@.dep

# force recompilation of database.o if the DATABASE has changed
database.o: database-${DATABASE}.o

%.do: %.c
	@echo CC $<
	@mkdir -p .depend
	@${CC} -c ${CFLAGS} ${DFLAGS} -o $@ $< -MMD -MF .depend/$@.dep

${OBJECTS}:  config.mk
${DOBJECTS}: config.mk

${PROJECT}: ${OBJECTS}
	@echo CC -o $@
	@${CC} ${SFLAGS} ${LDFLAGS} -o $@ ${OBJECTS} ${LIBS}

clean:
	@rm -rf ${PROJECT} ${OBJECTS} ${PROJECT}-${VERSION}.tar.gz \
		${DOBJECTS} ${PROJECT}-debug .depend

${PROJECT}-debug: ${DOBJECTS}
	@echo CC -o ${PROJECT}-debug
	@${CC} ${LDFLAGS} -o ${PROJECT}-debug ${DOBJECTS} ${LIBS}

debug: ${PROJECT}-debug

valgrind: debug
	valgrind --tool=memcheck --leak-check=yes --show-reachable=yes \
		./${PROJECT}-debug

gdb: debug
	cgdb ${PROJECT}-debug

dist: clean
	@${MAKE} -p ${PROJECT}-${VERSION}
	@cp -R LICENSE Makefile config.mk README \
			${PROJECT}.1 ${SOURCE} ${PROJECT}-${VERSION}
	@tar -cf ${PROJECT}-${VERSION}.tar ${PROJECT}-${VERSION}
	@gzip ${PROJECT}-${VERSION}.tar
	@rm -rf ${PROJECT}-${VERSION}

install: all
	@echo installing executable file
	@mkdir -p ${DESTDIR}${PREFIX}/bin
	@cp -f ${PROJECT} ${DESTDIR}${PREFIX}/bin
	@chmod 755 ${PROJECT} ${DESTDIR}${PREFIX}/bin/${PROJECT}
	@echo installing manual page
	@mkdir -p ${DESTDIR}${MANPREFIX}/man1
	@sed "s/VERSION/${VERSION}/g" < ${PROJECT}.1 > ${DESTDIR}${MANPREFIX}/man1/${PROJECT}.1
	@chmod 644 ${DESTDIR}${MANPREFIX}/man1/${PROJECT}.1

uninstall:
	@echo removing executable file
	@rm -f ${DESTDIR}${PREFIX}/bin/${PROJECT}
	@echo removing manual page
	@rm -f ${DESTDIR}${MANPREFIX}/man1/${PROJECT}.1

-include $(wildcard .depend/*.dep)

.PHONY: all options clean debug valgrind gdb dist install uninstall
