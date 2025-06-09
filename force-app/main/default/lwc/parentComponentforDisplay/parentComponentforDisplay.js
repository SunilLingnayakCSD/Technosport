import { LightningElement } from 'lwc';

export default class ParentComponentforDisplay extends LightningElement {

    isCheckedIn = false;

    handleCheckIn() {
        this.isCheckedIn = true;
    }
}