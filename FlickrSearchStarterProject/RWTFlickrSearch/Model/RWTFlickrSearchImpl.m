//
//  RWTFlickrSearchImpl.m
//  RWTFlickrSearch
//
//  Created by z on 2018/4/17.
//  Copyright © 2018年 Colin Eberhardt. All rights reserved.
//

#import "RWTFlickrSearchImpl.h"
#import "RWTFlickrPhotoMetadata.h"

@interface RWTFlickrSearchImpl () <OFFlickrAPIRequestDelegate>

@property (strong, nonatomic) NSMutableSet *requests;
@property (strong, nonatomic) OFFlickrAPIContext *flickrContext;

@end

@implementation RWTFlickrSearchImpl

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *OFSampleAppAPIKey = @"419305c0df930caaa750d6d6784d5788";
        NSString *OFSampleAppAPISharedSecret = @"bce635f364a8face";
        
        _flickrContext = [[OFFlickrAPIContext alloc] initWithAPIKey:OFSampleAppAPIKey
                                                       sharedSecret:OFSampleAppAPISharedSecret];
        _requests = [NSMutableSet new];
    }
    return  self;
}

- (RACSignal *)flickrSearchSignal:(NSString *)searchString {
    return [self signalFromAPIMethod:@"flickr.photos.search"
                           arguments:@{@"text": searchString,
                                       @"sort": @"interestingness-desc"}
                           transform:^id(NSDictionary *response) {
                               
                               RWTFlickrSearchResults *results = [RWTFlickrSearchResults new];
                               results.searchString = searchString;
                               results.totalResults = [[response valueForKeyPath:@"photos.total"] integerValue];
                               
                               NSArray *photos = [response valueForKeyPath:@"photos.photo"];
                               results.photos = [photos linq_select:^id(NSDictionary *jsonPhoto) {
                                   RWTFlickrPhoto *photo = [RWTFlickrPhoto new];
                                   photo.title = [jsonPhoto objectForKey:@"title"];
                                   photo.identifier = [jsonPhoto objectForKey:@"id"];
                                   photo.url = [self.flickrContext photoSourceURLFromDictionary:jsonPhoto
                                                                                           size:OFFlickrSmallSize];
                                   return photo;
                               }];
                               
                               return results;
                           }];
}

- (RACSignal *)signalFromAPIMethod:(NSString *)method
                         arguments:(NSDictionary *)args
                         transform:(id (^)(NSDictionary *response))block {
    
    // 1. Create a signal for this request
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        // 2. Create a Flick request object
        OFFlickrAPIRequest *flickrRequest =
        [[OFFlickrAPIRequest alloc] initWithAPIContext:self.flickrContext];
        flickrRequest.delegate = self;
        [self.requests addObject:flickrRequest];
        
        // 3. Create a signal from the delegate method
        RACSignal *successSignal =
        [self rac_signalForSelector:@selector(flickrAPIRequest:didCompleteWithResponse:)
                       fromProtocol:@protocol(OFFlickrAPIRequestDelegate)];
        
        // 4. Handle the response
        [[[successSignal
           map:^id(RACTuple *tuple) {
               return tuple.second;
           }]
          map:block]
         subscribeNext:^(id x) {
             [subscriber sendNext:x];
             [subscriber sendCompleted];
         }];
        
        // 5. Make the request
        [flickrRequest callAPIMethodWithGET:method
                                  arguments:args];
        
        // 6. When we are done, remove the reference to this request
        return [RACDisposable disposableWithBlock:^{
            [self.requests removeObject:flickrRequest];
        }];
    }];
}

- (RACSignal *)flickrImageMetadata:(NSString *)photoId {
    
    RACSignal *favourites = [self signalFromAPIMethod:@"flickr.photos.getFavorites"
                                            arguments:@{@"photo_id": photoId}
                                            transform:^id(NSDictionary *response) {
                                                NSString *total = [response valueForKeyPath:@"photo.total"];
                                                return total;
                                            }];
    
    RACSignal *comments = [self signalFromAPIMethod:@"flickr.photos.getInfo"
                                          arguments:@{@"photo_id": photoId}
                                          transform:^id(NSDictionary *response) {
                                              NSString *total = [response valueForKeyPath:@"photo.comments._text"];
                                              return total;
                                          }];
    
    return [[RACSignal combineLatest:@[favourites, comments] reduce:^id(NSString *favs, NSString *coms){
        RWTFlickrPhotoMetadata *meta = [RWTFlickrPhotoMetadata new];
        meta.comments = [coms integerValue];
        meta.favorites = [favs integerValue];
        return  meta;
    }] logAll];
}

@end
