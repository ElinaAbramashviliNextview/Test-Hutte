import { LightningElement, api } from "lwc";
import myJsonData from "@salesforce/resourceUrl/Z0773example"; // Import the static resource URL
import productName from "@salesforce/label/c.ProductConfiguratorLWCProductName";
import productNumber from "@salesforce/label/c.ProductConfiguratorLWCProductNumber";
import picklistPlaceholder from "@salesforce/label/c.ProductConfiguratorLWCExpandOptions";
import selectFamily from "@salesforce/label/c.ProductConfiguratorLWCSelectFamily";

const columns = [
  {
    label: productName,
    fieldName: "ItemName",
    type: "text",
    hideDefaultActions: true,
    clipText: true,
  },
  {
    label: productNumber,
    fieldName: "ItemCode",
    type: "text",
    hideDefaultActions: true,
    clipText: true,
  },
];
const productFamilies = [
  {
    label: "MICROOFFICE",
    value: "MICROOFFICE",
  },
  { label: "MICROOFFICE FURNITURE", value: "MICROOFFICE_FURNITURE" },
  { label: "OTHER", value: "OTHER" },
];
export default class ProductSelection extends LightningElement {
  label = {
    selectFamily,
    picklistPlaceholder,
  };
  columns = columns;
  productFamilies = productFamilies;
  @api productFamily;
  @api products;
  @api productToConfigure;
  currentPageIndex = 0;

  // renderedCallback() {
  //   this.focusOnPicklist();
  // }

  // focusOnPicklist(){
  //   const combobox = this.template.querySelector('lightning-combobox');
  //   if(combobox && !this.productFamily){
  //     console.log('focusing on combobox');
  //     combobox.focus();
  //   }
  // }

  connectedCallback() {
    if (this.productFamily) {
      this.loadJsonData();
    }
  }

  renderedCallback() {
    if (this.productFamily && this.productToConfigure) {
      this.selectRows([this.productToConfigure.ItemCode]);
    }
  }
  selectRows(rowKeysToSelect) {
    const childComponent = this.template.querySelector("c-product-table");
    if (childComponent) {
      childComponent.setSelectedRows(rowKeysToSelect); // Pass selected rows to child
    }
  }

  // Fetch and load the JSON data from the static resource
  loadJsonData() {
    fetch(myJsonData) // Fetch the static resource URL
      .then((response) => response.json()) // Parse the response as JSON
      .then((data) => {
        this.products = data;
      })
      .catch((error) => {
        console.error("Error loading JSON data:", error);
      });
  }

  get productsToDisplay() {
    return this.products.slice(this.startIndex, this.endIndex + 1);
  }

  setIndexesToDisplay() {
    this.startIndex = this.currentPageIndex * this.pageSize;
    this.endIndex = this.startIndex + this.pageSize;
  }

  handleFamilySelect(event) {
    this.productFamily = event.detail.value;
    // console.log("selected product family: ", this.productFamily);
    const familySelectedEvent = new CustomEvent("familyselected", {
      detail: this.productFamily,
    });
    this.dispatchEvent(familySelectedEvent);
    this.loadJsonData();
  }

  handleRowSelected(event) {
    this.productToConfigure = event.detail[0];
    // console.log("Product To Configure: ", this.productToConfigure.ItemName);
    const productSelectedEvent = new CustomEvent("productselected", {
      detail: this.productToConfigure,
    });
    this.dispatchEvent(productSelectedEvent);
  }

  @api resetData() {
    this.productFamily = undefined;
    this.products = undefined;
    this.productToConfigure = undefined;
  }
}
