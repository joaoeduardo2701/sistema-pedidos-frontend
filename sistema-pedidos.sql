CREATE DATABASE IF NOT EXISTS sistema_pedidos_db;
USE sistema_pedidos_db;

-- Tabela de Itens do Menu
CREATE TABLE tb_menu_item (
    id_item INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    descricao VARCHAR(255),
    preco DECIMAL(10, 2) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    disponivel BOOLEAN NOT NULL DEFAULT TRUE
);

-- Tabela de Cabeçalho do Pedido
CREATE TABLE tb_pedido (
    id_pedido INT PRIMARY KEY AUTO_INCREMENT,
    data_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, 
    status ENUM('Em Preparo', 'Aguardando Entrega', 'Pronto', 'Entregue', 'Cancelado') DEFAULT 'Em Preparo',
    valor_total DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    observacoes VARCHAR(255),
    id_mesa INT
);

-- Tabela de Detalhes (Onde a lista é salva)
CREATE TABLE tb_pedido_item (
    id_detalhe INT PRIMARY KEY AUTO_INCREMENT,
    id_pedido INT NOT NULL,
    id_item INT NOT NULL,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10, 2) NOT NULL, -- Salva o preço do momento da compra
    observacao_item VARCHAR(255),
    
    FOREIGN KEY (id_pedido) REFERENCES tb_pedido(id_pedido) ON DELETE CASCADE,
    FOREIGN KEY (id_item) REFERENCES tb_menu_item(id_item) ON DELETE NO ACTION
);

DELIMITER $$

CREATE PROCEDURE sp_CriarPedido(
    IN p_id_mesa INT,
    IN p_observacoes VARCHAR(255),
    IN p_itens_json JSON -- AQUI ENTRA A SUA LISTA DE ITENS
)
BEGIN
    DECLARE v_id_pedido INT;
    DECLARE v_erro BOOL DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET v_erro = 1;

    -- Iniciar Transação (Tudo ou Nada)
    START TRANSACTION;

    -- 1. Inserir o Cabeçalho do Pedido
    INSERT INTO tb_pedido (id_mesa, observacoes, status)
    VALUES (p_id_mesa, p_observacoes, 'Em Preparo');
    
    -- Pegar o ID gerado acabou de ser criado
    SET v_id_pedido = LAST_INSERT_ID();

    -- 2. Inserir os Itens da Lista JSON na tabela tb_pedido_item
    -- O Select abaixo busca o preço atual do item na tabela tb_menu_item para segurança
    INSERT INTO tb_pedido_item (id_pedido, id_item, quantidade, observacao_item, preco_unitario)
    SELECT 
        v_id_pedido,            -- ID do pedido criado acima
        jt.id_item,             -- ID do item vindo do JSON
        jt.quantidade,          -- Quantidade vinda do JSON
        jt.observacao,          -- Obs vinda do JSON
        m.preco                 -- Preço vindo da tabela Menu (Segurança!)
    FROM JSON_TABLE(p_itens_json, '$[*]' COLUMNS (
            id_item INT PATH '$.id_item',
            quantidade INT PATH '$.quantidade',
            observacao VARCHAR(255) PATH '$.observacao'
         )) AS jt
    INNER JOIN tb_menu_item m ON m.id_item = jt.id_item;

    -- 3. Atualizar o Valor Total do Pedido
    UPDATE tb_pedido 
    SET valor_total = (
        SELECT SUM(quantidade * preco_unitario) 
        FROM tb_pedido_item 
        WHERE id_pedido = v_id_pedido
    )
    WHERE id_pedido = v_id_pedido;

    -- Finalizar
    IF v_erro THEN
        ROLLBACK;
        SELECT 'Erro ao processar pedido' AS Mensagem;
    ELSE
        COMMIT;
        SELECT v_id_pedido AS id_pedido_gerado;
    END IF;

END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS sp_Pedido_ReadAll;

DELIMITER $$

CREATE PROCEDURE sp_Pedido_ReadAll()
BEGIN
    SELECT
        CAST(p.id_pedido AS SIGNED) AS IdPedido,
        p.data_hora AS DataHora,
        IFNULL(CAST(p.status AS CHAR), 'Em Preparo') AS Status, -- Retorna String
        CAST(p.valor_total AS DECIMAL(10, 2)) AS ValorTotal,
        IFNULL(p.observacoes, '') AS Observacoes,
        CAST(p.id_mesa AS SIGNED) AS IdMesa 
    FROM
        tb_pedido p
    ORDER BY
        p.data_hora DESC;
END$$
DELIMITER ;

DELIMITER $$

-- Listar um pedido específico por ID (para editar)
CREATE PROCEDURE sp_Pedido_ReadById(
    IN p_id_pedido INT
)
BEGIN
    -- Retorna os dados do pedido
    SELECT
        id_pedido,
        data_hora,
        status,
        valor_total,
        observacoes,
        id_mesa
    FROM
        tb_pedido
    WHERE
        id_pedido = p_id_pedido;
        
    -- Retorna os itens detalhados desse pedido (para rebuild no backend)
    SELECT
        id_detalhe,
        id_item,
        quantidade,
        preco_unitario,
        observacao_item
    FROM
        tb_pedido_item
    WHERE
        id_pedido = p_id_pedido;
END$$

DELIMITER ;

DELIMITER $$

-- Procedure para ATUALIZAR o status do pedido
CREATE PROCEDURE sp_Pedido_UpdateStatus(
    IN p_id_pedido INT,
    IN p_status ENUM('Em Preparo', 'Pronto', 'Entregue', 'Cancelado')
)
BEGIN
    UPDATE tb_pedido
    SET 
        status = p_status
    WHERE 
        id_pedido = p_id_pedido;
END$$

DELIMITER $$

-- Procedure para EXCLUIR um pedido
CREATE PROCEDURE sp_Pedido_Delete(
    IN p_id_pedido INT
)
BEGIN
    DELETE FROM tb_pedido
    WHERE id_pedido = p_id_pedido;
END$$

DELIMITER ;

DELIMITER ;

-- Itens no cardápio
select * from tb_menu_item;

CALL sp_CriarPedido(
    5, 
    'Cliente tem pressa', 
    '[
        {"id_item": 1, "quantidade": 2, "observacao": "Ao ponto"}, 
        {"id_item": 2, "quantidade": 1, "observacao": "Sem sal"},
        {"id_item": 3, "quantidade": 3, "observacao": "Gelo e limão"}
    ]'
);

SELECT * FROM tb_pedido;       -- Vai ver o total calculado (25*2 + 12*1 + 6*3 = 80.00)
SELECT * FROM tb_pedido_item;  -- Vai ver os 3 itens vinculados ao pedido

SELECT id_item, nome, preco FROM tb_menu_item;