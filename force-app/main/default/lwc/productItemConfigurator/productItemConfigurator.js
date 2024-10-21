import { api, LightningElement } from 'lwc';
import assistantTabLabel from "@salesforce/label/c.ProductConfiguratorAssistantTabLabel";
import choiceTabLabel from "@salesforce/label/c.ProductConfiguratorChoiceTabLabel";
import assistantCardLabel from "@salesforce/label/c.ProductConfiguratorAssistantCardLabel";
import choiceCardLabel from "@salesforce/label/c.ProductConfiguratorChoiceCardLabel";

export default class ProductItemConfigurator extends LightningElement {
    label = {
        assistantTabLabel,
        choiceTabLabel,
        assistantCardLabel,
        choiceCardLabel
    };
    cardTitle = assistantCardLabel;
    assistantTabActive;
    @api productToConfigure;
    configuredProduct;

    handleActiveTab(event) {
        if (event.target.label === this.label.assistantTabLabel) {
            this.cardTitle = this.label.assistantCardLabel;
            this.assistantTabActive = true;
        } else if (event.target.label === this.label.choiceTabLabel) {
            this.cardTitle = this.label.choiceCardLabel;
            this.assistantTabActive = false;
        }
    }

    handleItemConfiguration(event){
    }
}