import { LightningElement, track } from 'lwc';

export default class CreateVisit extends LightningElement {
    @track isshow=false
    showpopup(){
        this.isshow=true
    }
}