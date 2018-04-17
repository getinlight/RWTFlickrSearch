//
//  RWTFlickrSearchViewModel.m
//  RWTFlickrSearch
//
//  Created by z on 2018/4/17.
//  Copyright © 2018年 Colin Eberhardt. All rights reserved.
//

#import "RWTFlickrSearchViewModel.h"
#import "RWTSearchResultsViewModel.h"

@interface RWTFlickrSearchViewModel ()

@property (nonatomic, weak) id<RWTViewModelServices> services;

@end

@implementation RWTFlickrSearchViewModel

- (instancetype) initWithServices:(id<RWTViewModelServices>)services {
    self = [super init];
    if (self) {
        _services = services;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.title = @"Flickr Search";
    
    RACSignal *validSearchSignal =
    [[RACObserve(self, searchText)
      map:^id(NSString *text) {
          return @(text.length > 3);
      }] distinctUntilChanged];
    
    [validSearchSignal subscribeNext:^(id x) {
        NSLog(@"search text is valid %@", x);
    }];
    
    self.executeSearch =
    [[RACCommand alloc] initWithEnabled:validSearchSignal
                            signalBlock:^RACSignal *(id input) {
                                return  [self executeSearchSignal];
                            }];
}

- (RACSignal *)executeSearchSignal {
    return [[[self.services getFlickrSearchService]
             flickrSearchSignal:self.searchText]
            doNext:^(id result) {
                RWTSearchResultsViewModel *resultsViewModel =
                [[RWTSearchResultsViewModel alloc] initWithSearchResults:result services:self.services];
                [self.services pushViewModel:resultsViewModel];
            }];
}

@end
