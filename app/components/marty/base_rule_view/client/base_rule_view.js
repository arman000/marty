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

    const column_name = cell.column.config.name;
    const with_not = obj.data[`${column_name}_not`];

    if (with_not) {
      return `NOT (${value})`;
    }

    return value;
  }
});
