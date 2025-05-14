package edu.sustech.cs307.logicalOperator;

import net.sf.jsqlparser.expression.Expression;

import java.util.Collections;

public class LogicalDeleteOperator extends LogicalOperator {
    public final String tableName;
    public final Expression whereExpr;  // 可为 null，表示无 WHERE 条件

    public LogicalDeleteOperator(String tableName, Expression whereExpr) {
        super(Collections.emptyList()); // 没有子操作符，Delete 直接作用于表
        this.tableName = tableName;
        this.whereExpr = whereExpr;
    }

    @Override
    public String toString() {
        return "DeleteOperator(table=" + tableName + ", where=" + whereExpr + ")";
    }
}
