/*
供 otter 使用， otter 需要对 retl.* 的读写权限，以及对业务表的读写权限
1. 创建database retl
*/
# drop database if exists retl;
# create database if not exists retl;
create database retl;

/* 2. 用户授权 给同步用户授权 */
# CREATE USER retl@'%' IDENTIFIED BY 'retl';
# GRANT USAGE ON *.* TO `retl`@'%';
# GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO `retl`@'%';
# GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON `retl`.* TO `retl`@'%';
/* 业务表授权，这里可以限定只授权同步业务的表 */
# GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO `retl`@'%';  

/* 3. 创建系统表 */
USE retl;

create table retl_buffer
(
    ID BIGINT AUTO_INCREMENT comment '无意义，自增即可' PRIMARY KEY,
    TABLE_ID INT(11) NOT NULL comment 'tableId, 可通过Manager后台的数据表配置界面查看“序号”这一列。如果配置的是正则，需要指定full_name，当前table_id设置为0',
    FULL_NAME varchar(512) comment 'schemaName.tableName  (如果明确指定了table_id，可以不用指定full_name)',
    TYPE CHAR(1) NOT NULL comment 'I/U/D ，分别对应于insert/update/delete',
    PK_DATA VARCHAR(256) NOT NULL comment '如果是复合主键，多个pk之间使用char(1)进行分隔',
    GMT_CREATE TIMESTAMP NOT NULL comment '无意义，系统时间即可',
    GMT_MODIFIED TIMESTAMP default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP comment '无意义，系统时间即可'
) ENGINE=InnoDB comment 'otter自定义数据同步（自由门）跳板表' CHARSET=utf8;

# 全量同步操作触发示例（把实际表的主键全部查出来插入，otter同步到这个表数据时会自动进行数据修补）：
# insert into retl.retl_buffer(ID,TABLE_ID, FULL_NAME,TYPE,PK_DATA,GMT_CREATE,GMT_MODIFIED) (select null,0,'$schema.table$','I',id,now(),now() from $schema.table$); 

create table retl_mark
(   
    ID BIGINT AUTO_INCREMENT,
    CHANNEL_ID INT(11),
    CHANNEL_INFO varchar(128),
    CONSTRAINT RETL_MARK_ID PRIMARY KEY (ID) 
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

create table xdual (
  ID BIGINT(20) NOT NULL AUTO_INCREMENT,
  X timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

/* 4. 插入初始化数据 */
INSERT INTO retl.xdual(id, x) VALUES (1,now()) ON DUPLICATE KEY UPDATE x = now();
