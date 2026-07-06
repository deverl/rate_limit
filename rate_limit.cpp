// Should rate limit
// 4 cases
//   1: key not in cache (create new entry, count = 1, return false)
//   2: key in cache, not expired, count < max (increment count, return false)
//   3. key in cache, not expired, count >= max (return true)
//   4. key in cache, expired (create new entry, count = 1, return false)

#include <iostream>

#include <unordered_map>
#include <chrono>

using namespace std;

class RateLimit
{
public:
    RateLimit(int max, int duration) : max_(max), duration_(duration) {}

    bool shouldRateLimit(const string& key)
    {
        if(++callCount_ % kEvictEvery == 0)
        {
            evictExpired();
        }

        // steady_clock is monotonic: unaffected by system clock adjustments.
        auto now = chrono::steady_clock::now();
        auto it = cache_.find(key);
        if(it == cache_.end())
        {
            // Case 1
            cache_[key] = make_pair(now + chrono::seconds(duration_), 1);
            return false;
        }

        auto& entry = it->second;
        if(now < entry.first)
        {
            if(entry.second < max_)
            {
                // Case 2
                entry.second++;
                return false;
            }
            else
            {
                // Case 3
                return true;
            }
        }
        else
        {
            // Case 4
            entry.first = now + chrono::seconds(duration_);
            entry.second = 1;
            return false;
        }
    }
protected:
    // Sweep expired entries every Nth call so stale keys
    // don't accumulate forever.
    static const int kEvictEvery = 100;

    void evictExpired()
    {
        auto now = chrono::steady_clock::now();
        for(auto it = cache_.begin(); it != cache_.end(); )
        {
            if(now >= it->second.first)
            {
                it = cache_.erase(it);
            }
            else
            {
                ++it;
            }
        }
    }

    int max_;
    int duration_;
    long callCount_ = 0;
    unordered_map<string, pair<chrono::steady_clock::time_point, int> > cache_;
};


int main()
{
    RateLimit rl(3, 5);

    // false
    cout << rl.shouldRateLimit("device") << endl;
    cout << rl.shouldRateLimit("device") << endl;
    cout << rl.shouldRateLimit("device") << endl;

    // true
    cout << rl.shouldRateLimit("device") << endl;

    return 0;
}
