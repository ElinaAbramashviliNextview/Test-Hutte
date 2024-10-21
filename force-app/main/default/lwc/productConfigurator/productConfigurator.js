import { LightningElement } from 'lwc';
import productConfiguratorHeader from '@salesforce/label/c.ProductConfiguratorLWCHeader';
import next from '@salesforce/label/c.Next';
import back from '@salesforce/label/c.Back';
import cancel from '@salesforce/label/c.Cancel';

export default class ProductConfigurator extends LightningElement {
  label = {
    productConfiguratorHeader,
    next,
    back,
    cancel,
  };
  currentStepIndex = 0;
  productToConfigure;
  productFamily;

  handleProductSelected(event) {
    this.productToConfigure = event.detail;
    console.log('ProductToConfigure', this.productToConfigure.ItemName);
  }

  handleFamilySelected(event) {
    this.productFamily = event.detail;
    console.log('Product Family: ', this.productFamily);
  }

  handleClose() {
    const childComponent = this.template.querySelector('c-product-selection');
    if (childComponent) {
      childComponent.resetData();
    }
    this.currentStepIndex = 0;
    this.productToConfigure = undefined;
    this.productFamily = undefined;
    this.dispatchEvent(new CustomEvent('closeprodmodal', {}));
  }

  handleNext() {
    this.currentStepIndex += 1;
  }

  get nextDisabled() {
    return !(this.currentStepIndex == 0 && this.productToConfigure);
  }

  handlePrev() {
    this.currentStepIndex -= 1;
  }

  get productSelectionStep() {
    return this.currentStepIndex == 0;
  }
}
