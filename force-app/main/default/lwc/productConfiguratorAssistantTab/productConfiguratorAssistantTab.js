import { api, LightningElement } from 'lwc';

export default class ProductConfiguratorAssistantTab extends LightningElement {
    @api productToConfigure;

    get tabStructure() {
        return this.prepareItems(this.productToConfigure);
    }

    prepareItems(product) {
        return {
            label: product.ItemName,
            name: product.ItemCode,
            items: product.ProductTreeLines ? product.ProductTreeLines.map(item => this.prepareItems(item)) : []
        };
    }
}