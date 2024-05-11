// Should rate limit
// 4 cases
//   1: key not in cache (create new entry, count = 1, return false)
//   2: key in cache, not expired, count < max (increment count, return false)
//   3. key in cache, not expired, count >= max (increment count, return true)
//   4. key in cache, expired (create new entry, count = 1, return false)

#include <iostream>

#include <unordered_map>
#include <chrono>
#include <ctime>

using namespace std;

class RateLimit
{
public:
    RateLimit(int max, int duration) : max_(max), duration_(duration) {}

    bool shouldRateLimit(const string& key)
    {
        auto now = chrono::system_clock::now();
        auto it = cache_.find(key);
        if(it == cache_.end())
        {
            // Case 1
            cache_[key] = make_pair(now, 1);
            return false;
        }

        auto& entry = it->second;
        auto elapsed = chrono::duration_cast<chrono::seconds>(now - entry.first).count();
        if(elapsed < duration_)
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
                entry.second++;
                return true;
            }
        }
        else
        {
            // Case 4
            cache_[key] = make_pair(now, 1);
            return false;
        }
    }
protected:
    int max_;
    int duration_;
    unordered_map<string, pair<chrono::system_clock::time_point, int> > cache_;
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

