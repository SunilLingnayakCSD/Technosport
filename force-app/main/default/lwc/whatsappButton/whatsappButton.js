import { LightningElement } from 'lwc';
import whatsappIcon from '@salesforce/resourceUrl/whatsapp'; // Name of static resource

export default class WhatsappButton extends LightningElement {
    whatsappImage = whatsappIcon;

    navigateToWhatsApp() {
        const message = encodeURIComponent("Hi, Hope you are doing well. We are visiting your store today.");
        const url = `https://wa.me/?text=${message}`;
        window.open(url, "_blank");
    }
}