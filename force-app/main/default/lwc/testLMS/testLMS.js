import { LightningElement,wire,track } from 'lwc';
import cartMessageChannel from '@salesforce/messageChannel/cartMessageChannel__c';
import { subscribe, APPLICATION_SCOPE, MessageContext,unsubscribe } from 'lightning/messageService';
import returnImage from '@salesforce/apex/TestImage.returnImage'
export default class TestLMS extends LightningElement {
    // @wire(MessageContext)
    // messageContext;
    //         @track cartData;
    //         @track d=[]
    //         subscription = null;
    //         subscribeToMessageChannel() {
    //             if (!this.subscription) {
    //                 this.subscription = subscribe(
    //                     this.messageContext,
    //                     cartMessageChannel,
    //                     (message) => this.handleMessage(message),
    //                     { scope: APPLICATION_SCOPE }
    //                 );
    //             }
    //         }
    //         connectedCallback() {
    //             this.subscribeToMessageChannel();
    //         }
        
    //         handleMessage(message) {
    //             console.log('Received message:', message);
    //             this.cartData=message.cartData ? message.cartData: {}
    //             this.d.push(this.cartData)
    //             console.log('Recived Message',JSON.stringify(this.d,null,2));
    //         }
        
           
    //         handleUnSubscribe() {
    //             console.log('Unsubscribe');
    //             unsubscribe(this.subscription);
    //             this.subscription=null
    //             this.cartData=[]
    //         }
    img
    // @wire(returnImage)
    // wiredata({data,error}){
    //     if(data){
    //         this.img=data
    //         console.log('Image',this.cartData)
    //     }else{
    //     console.log('====================================');
    //     console.log(error);
    //     console.log('====================================');
    //     }
    // }
    connectedCallback(){
        returnImage().then(result=>{
            this.img=result
            console.log('Image',this.img)
        }).catch(error=>{
            console.log('====================================');
            console.log(error);
            console.log('====================================');
        })
    }
}