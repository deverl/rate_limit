
import java.util.*;

// Should rate limit
// 4 cases
//   1: key not in cache (create new entry, count = 1, return false)
//   2: key in cache, not expired, count < max (increment count, return false)
//   3. key in cache, not expired, count >= max (return true)
//   4. key in cache, expired (create new entry, count = 1, return false)

class RateLimit {
    public static void main(String[] args) {
    
        //false
        System.out.println(rateLimit("device_info", 30, 3));
        System.out.println(rateLimit("device_info", 30, 3));
        System.out.println(rateLimit("device_info", 30, 3));
    
        //true
        System.out.println(rateLimit("device_info", 30, 3));
    }
    
    static class Tuple {
        long scaleSeconds;
        int  numberRequests;
    }
    
    static HashMap<String, Tuple> cache = new HashMap<String, Tuple>();
    
    public static boolean rateLimit(String key, int intervalInSecs, int maxLimit) {
        // Fixed window counter solution
        // 1. Get the current bucket, see if it has expired, if "yes", create one
        // 2. See if the bucket is already full, if "yes", return "true", 
        // 3. if the bucket is not full, increment the bucket counter and return "false"
        long currTimeSecs = System.currentTimeMillis() / 1000;
        long scaleSeconds = currTimeSecs / intervalInSecs;
    
        if(cache.containsKey(key)){
            Tuple tuple = cache.get(key);
    
            if(tuple.scaleSeconds == scaleSeconds){
                // Bucket found for this period 
                if(tuple.numberRequests >= maxLimit){
                    // Case 3
                    // Block
                    return true; 
                }
                // Case 2
                tuple.numberRequests += 1;
                cache.put(key, tuple);
                return false;
            } else {
                // Case 4
                // The bucket has expired, replace with a new one
                tuple = new Tuple();
                tuple.scaleSeconds = scaleSeconds;
                tuple.numberRequests = 1;
    
                cache.put(key, tuple);
                // Do not block
                return false;
            }
    
        } else {
            // Case 1
            // Bucket not found, create a new one
            Tuple tuple = new Tuple();
            tuple.scaleSeconds = scaleSeconds;
            tuple.numberRequests = 1;
    
            cache.put(key, tuple);
    
            // Do not block
            return false;
        }
    }
}