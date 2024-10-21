import { LightningElement, api } from 'lwc';
import productName from "@salesforce/label/c.ProductConfiguratorLWCProductName";
import productNumber from "@salesforce/label/c.ProductConfiguratorLWCProductNumber";
import quantity from '@salesforce/label/c.Quantity';
import currency from '@salesforce/label/c.Currency';
import price from '@salesforce/label/c.Price';
import total from '@salesforce/label/c.Total';
import noConfigText from '@salesforce/label/c.ProductConfiguratorNoConfig';

const choiceTableColumns = [
  { label: 'Level', fieldName: 'Level', type: 'number', initialWidth: 30 },
  {
    label: productName,
    fieldName: 'ItemCode',
    type: 'text',
    initialWidth: 80
  },
  {
    label: productNumber,
    fieldName: 'ItemName',
    type: 'text'
  },
  {
    label: quantity,
    fieldName: 'Quantity',
    type: 'number',
    initialWidth: 100
  },
  {
    label: currency,
    fieldName: 'Currency',
    type: 'text',
    initialWidth: 100
  },
  {
    label: price,
    fieldName: 'ItemPrice',
    type: 'number',
    initialWidth: 150
  },
  {
    label: total,
    fieldName: 'TotalPrice',
    type: 'number',
    initialWidth: 150
  },
];
export default class ProductConfiguratorChoiceTab extends LightningElement {
  label = {
    noConfigText
  }
  columns = choiceTableColumns.map((column) => {
    return {
      ...column,
      hideDefaultActions: true,
      clipText: true,
    };
  });
  @api configuredProduct;
  configuration = [];

  connectedCallback() {
    if (this.configuredProduct) {
      this.configuration = this.flattenConfiguration(this.configuredProduct);
    }
  }

  flattenConfiguration(parent, level = 0) {
    if (parent && Array.isArray(parent.ProductTreeLines)) {
      return parent.ProductTreeLines.flatMap((child) => {
        return [
          this.fieldsToKeep(child, level),
          ...(child.ProductTreeLines ? this.flattenConfiguration(child, level + 1) : []),
        ];
      });
    }
    return [];
  }

  fieldsToKeep(item, level) {
    return {
      Level: level,
      ItemName: item.ItemName,
      ItemCode: item.ItemCode,
      Currency: item.Currency,
      ItemPrice: item.Price
    };
  }
}
