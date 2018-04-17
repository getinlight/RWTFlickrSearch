//
//  Created by Colin Eberhardt on 26/04/2014.
//  Copyright (c) 2014 Colin Eberhardt. All rights reserved.
//

#import "RWTSearchResultsTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "RWTFlickrPhoto.h"
#import "RWTSearchResultsItemViewModel.h"

@interface RWTSearchResultsTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageThumbnailView;
@property (weak, nonatomic) IBOutlet UILabel *favouritesLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentsLabel;
@property (weak, nonatomic) IBOutlet UIImageView *commentsIcon;
@property (weak, nonatomic) IBOutlet UIImageView *favouritesIcon;

@end

@implementation RWTSearchResultsTableViewCell

- (void)bindViewModel:(id)viewModel {
    RWTSearchResultsItemViewModel *photo = viewModel;
    self.titleLabel.text = photo.title;
    
    self.imageThumbnailView.contentMode = UIViewContentModeScaleToFill;
    
    [self.imageThumbnailView sd_setImageWithURL:photo.url];
    
    [RACObserve(photo, favorites) subscribeNext:^(NSNumber *x) {
        self.favouritesLabel.text = [x stringValue];
        self.favouritesIcon.hidden = (x == nil);
    }];
    
    [RACObserve(photo, comments) subscribeNext:^(NSNumber *x) {
        self.commentsLabel.text = [x stringValue];
        self.commentsIcon.hidden = (x == nil);
    }];
    
    photo.isVisible = YES;
    
}

- (void)setParallax:(CGFloat)value {
    self.imageThumbnailView.transform = CGAffineTransformMakeTranslation(0, value);
}

@end
