import { LightningElement, api } from "lwc";

export default class ProductTable extends LightningElement {
  selectedRowKeys = [];
  @api columns;
  @api tableData;
  @api maxRowSelection = 1;
  @api keyField;
  @api hideCheckboxColumn = false;

  handleRowSelected(event) {
    const selectedRows = event.detail.selectedRows;

    const selectedEvent = new CustomEvent("rowselected", {
      detail: selectedRows,
    });
    this.dispatchEvent(selectedEvent);
  }

  @api
  setSelectedRows(selectedRows) {
    this.selectedRowKeys = selectedRows;
  }
}
