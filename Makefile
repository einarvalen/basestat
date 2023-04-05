.SUFFIXES: .d .o

SHELL = /bin/sh
DMD := dmd
RM := rm -f

TARGET := basestat
TEST_TARGET := basestat-test

SOURCE_FILES := $(shell echo *.d)
OBJECT_FILES := $(subst .d,.o, $(SOURCE_FILES) ) 

DEBUG := 
UNITTEST := -unittest 
CODE := -release

.PHONY: all
all :
	@echo Usage: 
	@echo "make <clean> | <test [-e DEBUG=-debug=Collect]> | <prod>"

.PHONY: prod
prod : $(TARGET) 
prod : FLAGS := $(DEBUG) $(CODE) 

.PHONY: dbg
	dbg : $(TARGET)
	dbg : FLAGS := -debug=ps

.PHONY: test 
test : FLAGS := $(DEBUG) $(UNITTEST)
test : $(TEST_TARGET)
	./$(TEST_TARGET) --json 

.PHONY: clean
clean : 
	$(RM) $(OBJECT_FILES) $(TARGET) $(TEST_TARGET)

$(TARGET) : $(OBJECT_FILES)
	$(DMD) -of$@ $(OBJECT_FILES) 

$(TEST_TARGET) : $(OBJECT_FILES) 
	$(DMD) -of$@ $(OBJECT_FILES) 

.d.o : 
	$(DMD) -c $(FLAGS) $(SOURCE_FILES)

