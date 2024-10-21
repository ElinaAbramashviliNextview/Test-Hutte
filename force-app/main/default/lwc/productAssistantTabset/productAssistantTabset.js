import { api, LightningElement } from 'lwc';

export default class ProductAssistantTabset extends LightningElement {
    @api tabStructure;

    get tabStructureToDisplay() {

    }

    handleActive(event) {
        console.log('----------------');
        console.log('event.target.value: ', event.target.value);
        console.log('event.target.label: ', event.target.label);
        console.log('----------------');
    }
}