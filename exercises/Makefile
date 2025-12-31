ASM = nasm
ASM_FLAGS = -f elf64
LD = ld
TARGET = exercise
OBJ = exercise.o

CYAN = \033[0;36m
NC = \033[0m

run:
	@$(ASM) $(ASM_FLAGS) $(filter-out $@,$(MAKECMDGOALS)).asm -o $(OBJ)
	@$(LD) $(OBJ) -o $(TARGET)
	@printf "$(CYAN)----- Running ASM: %s -----$(NC)\n" "$(filter-out $@,$(MAKECMDGOALS))"
	@./$(TARGET)
	@rm -f $(OBJ) $(TARGET)

%:
	@:
