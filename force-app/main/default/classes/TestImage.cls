public class TestImage {
@AuraEnabled(cacheable=true)
        public static String returnImage(){
        return 'https://drive.google.com/file/d/1dbFOdWszHLY5ymP6XettHUd3PctyAoHu/view?usp=drivesdk';
    }
}