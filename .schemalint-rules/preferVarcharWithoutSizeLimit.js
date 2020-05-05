const preferVarcharWithoutSizeLimit = {
  name: "prefer-varchar-without-size-limit",
  docs: {
    description: "Prefer using VARCHAR without size limit over varchar(255)",
    url: "..."
  },

  process({ schemaObject, report }) {
    const validator = ({ name: tableName }) => (column) => {
      const columnName = column.name;
      const type = column.type;

      if (type.startsWith("varchar") && column.maxLength) {
        report({
          rule: this.name,
          identifier: `${schemaObject.name}.${tableName}.${columnName}`,
          message: `Prefer varchar to ${type}(${column.maxLength}) types`,
          suggestedMigration: `ALTER TABLE "${tableName}" ALTER COLUMN "${columnName}" TYPE VARCHAR;`
        });
      }
    };

    schemaObject.tables.forEach((table) => {
      table.columns.forEach(validator(table));
    });
  }
};

module.exports = preferVarcharWithoutSizeLimit;
