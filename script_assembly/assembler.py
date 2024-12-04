def gerar_mif(instrucoes):
    # Mapeamento das instruções para código binário
    codigos_instrucoes = {
        "ADD": "0001",
        "SUB": "0010",
        "AND": "0011",
        "OR": "0100",
        "NOT": "0101",
        "CMP": "1000",
        "JMP": "1011",
        "JEQ": "1100",
        "JGR": "1101",
        "LOAD": "1001",
        "STORE": "1010",
        "MOV": "1110",
        "IN": "0110",
        "OUT": "0111",
        "WAIT": "1111",
        "IGNORAR": "0000"  # Linha de comentário ou instrução que não faz nada
    }
    
    # Mapeamento dos registradores
    codigos_registradores = {
        "A": "00",
        "B": "01",
        "R": "10",
        "I": "11"
    }
    
    # Função para converter números para binário de 8 bits
    def to_bin(n):
        try:
            # Se for um número decimal (int), converte para binário de 8 bits
            return format(int(n), '08b')
        except ValueError:
            # Se for um número em formato binário (já representado como string), apenas retorna
            return n.zfill(8)
    
    # Lista para armazenar as palavras de memória
    memoria = ["00000000"] * 256  # Inicializa a memória com 256 palavras de 8 bits 00000000
    endereco_memoria = 0  # Começamos no endereço 0
    
    # Mapeamento de rótulos (loop e labels)
    labels = {}
    
    # Variáveis para armazenar endereços de controle de fluxo
    loop_start = None
    end_loop = None
    att = None  # Variável para "att" que irá armazenar o endereço de JEQ que precisa ser atualizado
    
    # Função para processar uma linha de instrução
    def processar_instrucao(instrucao):
        nonlocal endereco_memoria, loop_start, end_loop, att

        partes = instrucao.strip().split()
        
        # Ignorar linhas vazias ou com instruções que não fazem nada
        if not partes or partes[0] == "IGNORAR":
            return None
        
        # Tratando rótulos (por exemplo, LOOP_START:)
        if partes[0].endswith(':'):
            label = partes[0][:-1]
            labels[label] = endereco_memoria
            return None
        
        # Verifica o código da instrução
        codigo_instrucao = codigos_instrucoes.get(partes[0], None)
        
        if not codigo_instrucao:
            print(f"Instrução não reconhecida: {partes[0]}")
            return None
        
        if partes[0] in ["ADD", "SUB", "AND", "OR", "NOT", "CMP", "MOV"]:
            # Para operações exec e de controle sem endereço
            instrucao_completa = codigo_instrucao

            # Verifica o primeiro argumento (registrador ou número imediato)
            if len(partes) > 1:
                reg_dest = codigos_registradores.get(partes[1], None)
                if reg_dest:
                    instrucao_completa += reg_dest
                else:
                    print(f"Erro: Registrador desconhecido {partes[1]}")
                    return None

            # Verifica o segundo argumento (registrador ou número imediato)
            if len(partes) > 2:
                if partes[2] in codigos_registradores:  # É um registrador
                    reg_or_num = codigos_registradores[partes[2]]
                    instrucao_completa += reg_or_num
                else:  # Não é um registrador, trata como número imediato
                    instrucao_completa += "11"  # Flag para indicar número imediato
                    memoria[endereco_memoria] = instrucao_completa  # Grava a instrução
                    endereco_memoria += 1

                    # Adiciona o número imediato no próximo endereço
                    numero = to_bin(partes[2])
                    memoria[endereco_memoria] = numero
                    endereco_memoria += 1
                    return  # Finaliza o processamento dessa instrução
            else:
                # Se não há segundo argumento, preenche com "00"
                instrucao_completa += "00"

            memoria[endereco_memoria] = instrucao_completa
            endereco_memoria += 1
        
        elif partes[0] in ["JMP", "JEQ", "JGR"]:
            # Instruções de controle de fluxo com endereço (salto)
            instrucao_completa = codigo_instrucao
            endereco_destino = labels.get(partes[1], None)
            
            if endereco_destino is None:
                print(f"Erro: rótulo {partes[1]} não encontrado.")
                return None
            
            # O código da instrução é preenchido com "00" para o registrador de controle
            instrucao_completa += "00"
            memoria[endereco_memoria] = instrucao_completa
            endereco_memoria += 1
            
            # Armazenar o endereço de destino para o salto
            if partes[0] == "JEQ":
                # Armazenar o endereço de onde o JEQ foi encontrado, para ser atualizado posteriormente
                att = endereco_memoria
                # Preenche com um endereço temporário (a ser atualizado depois)
                memoria[endereco_memoria] = "00000000"  # Endereço temporário
                endereco_memoria += 1
            else:
                # Preenche diretamente com o endereço de salto
                memoria[endereco_memoria] = to_bin(endereco_destino)
                endereco_memoria += 1
        
        elif partes[0] in ["LOAD", "STORE", "IN", "OUT"]:
            # Instruções de memória com endereço
            instrucao_completa = codigo_instrucao
            
            # Verifica o primeiro argumento (registrador ou número imediato)
            if len(partes) > 1:
                reg_dest = codigos_registradores.get(partes[1], None)
                if reg_dest:
                    instrucao_completa += reg_dest
                else:
                    print(f"Erro: Registrador desconhecido {partes[1]}")
                    return None

            # Verifica o segundo argumento (registrador ou número imediato/endereço)
            if len(partes) > 2:
                if partes[2] in codigos_registradores:  # É um registrador
                    reg_or_num = codigos_registradores[partes[2]]
                    instrucao_completa += reg_or_num
                else:  # Não é um registrador, trata como número imediato ou endereço
                    instrucao_completa += "11"  # Flag para indicar número imediato
                    memoria[endereco_memoria] = instrucao_completa  # Grava a instrução
                    endereco_memoria += 1

                    # Adiciona o número imediato ou endereço no próximo endereço
                    numero = to_bin(partes[2])
                    memoria[endereco_memoria] = numero
                    endereco_memoria += 1
                    return  # Finaliza o processamento dessa instrução
            else:
                # Se não há segundo argumento, preenche com "00"
                instrucao_completa += "00"
            
            memoria[endereco_memoria] = instrucao_completa
            endereco_memoria += 1

        
        elif partes[0] == "WAIT":
            # WAIT é uma instrução especial
            instrucao_completa = codigo_instrucao + "0000"  # Apenas quatro zeros após 1111
            memoria[endereco_memoria] = instrucao_completa
            endereco_memoria += 1

        if partes[0] == "LOOP_START:":
            loop_start = endereco_memoria
            
        # Quando encontramos o rótulo END_LOOP, armazenamos o endereço
        if partes[0] == "END_LOOP:":
            end_loop = endereco_memoria

            # Agora precisamos atualizar o JEQ com o endereço de END_LOOP
            if att is not None:
                memoria[att] = to_bin(end_loop)  # Atualiza o JEQ com o endereço correto
                att = None  # Limpa a variável att após atualizar o endereço

        return True
    
    # Processa todas as instruções
    for instrucao in instrucoes:
        processar_instrucao(instrucao)
    
    # Gerar arquivo MIF
    with open('saida.mif', 'w') as f:
        f.write("DEPTH = 256;\n")
        f.write("WIDTH = 8;\n")
        f.write("ADDRESS_RADIX = HEX;\n")
        f.write("DATA_RADIX = BIN;\n")
        f.write("CONTENT\n")
        f.write("BEGIN\n")
        
        for i, palavra in enumerate(memoria):
            f.write(f"{i:02X} : {palavra};\n")
        
        f.write("END;\n")

def ler_instrucoes_do_arquivo(nome_arquivo):
    with open(nome_arquivo, 'r') as f:
        return f.readlines()

# Exemplo de uso:
if __name__ == "__main__":
    # Lê as instruções de um arquivo txt
    instrucoes = ler_instrucoes_do_arquivo("instrucoes.txt")
    
    # Gera o arquivo MIF com as instruções
    gerar_mif(instrucoes)
    print("Arquivo MIF gerado com sucesso!")
