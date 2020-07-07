({
  simpleGuardColumnRenderer(value, cell, obj) {
    if (value === undefined || value === null) {
      return value;
    }

    if (
      !(cell && cell.column && cell.column.config && cell.column.config.name)
    ) {
      return value;
    }

    if (!(obj && obj.data)) {
      return value;
    }

    const columnName = cell.column.config.name;
    const withNot = obj.data[`${columnName}_not`];

    if (withNot) {
      return `NOT (${value})`;
    }

    return value;
  }
});
