import { LightningElement, wire } from 'lwc';
import getRecentProducts from '@salesforce/apex/ProductCarouselController.getRecentProducts';

export default class VideoCarousel extends LightningElement {
    products = [];
    currentIndex = 0;
    autoplay = true;

    // Wire service to fetch data from Apex controller
    @wire(getRecentProducts)
    wiredProducts({ error, data }) {
        if (data) {
            this.products = data;
        } else if (error) {
            console.error('Error fetching products', error);
        }
    }

    // Stop autoplay when the button is clicked
    stopAutoPlay() {
        this.autoplay = false;
    }

    // Next button logic
    goToNext() {
        if (this.currentIndex < this.products.length - 1) {
            this.currentIndex += 1;
        } else {
            this.currentIndex = 0; // Loop back to the first item
        }
    }

    // Previous button logic
    goToPrevious() {
        if (this.currentIndex > 0) {
            this.currentIndex -= 1;
        } else {
            this.currentIndex = this.products.length - 1; // Loop back to the last item
        }
    }

    // Autoplay functionality to auto-advance the carousel
    autoplayCarousel() {
        if (this.autoplay && this.products.length > 0) {
            setTimeout(() => {
                this.goToNext();
                this.autoplayCarousel(); // Recursive call for continuous autoplay
            }, 5000); // 5 seconds delay between slides
        }
    }

    connectedCallback() {
        this.autoplayCarousel();
    }
}