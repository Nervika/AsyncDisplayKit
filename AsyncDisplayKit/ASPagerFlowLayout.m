//
//  ASPagerFlowLayout.m
//  AsyncDisplayKit
//
//  Created by Levi McCallum on 2/12/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "ASPagerFlowLayout.h"

@interface ASPagerFlowLayout ()

@property (strong, nonatomic) NSIndexPath *currentIndexPath;

@end

@implementation ASPagerFlowLayout {
    BOOL _didRotate;
    CGRect _cachedCollectionViewBounds;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    NSInteger currentPage = ceil(proposedContentOffset.x / self.collectionView.bounds.size.width);
    self.currentIndexPath = [NSIndexPath indexPathForItem:currentPage inSection:0];
    
    return [super targetContentOffsetForProposedContentOffset:proposedContentOffset withScrollingVelocity:velocity];
}


- (void)prepareForAnimatedBoundsChange:(CGRect)oldBounds
{
  // Cache the current page if a rotation did happen. This happens before the rotation animation
  // is occuring and the bounds changed so we use this as an opportunity to cache the current index path
  if (_cachedCollectionViewBounds.size.width != self.collectionView.bounds.size.width) {
      _cachedCollectionViewBounds = self.collectionView.bounds;
        
    // Figurring out current page based on the old bounds visible space
    CGRect visibleRect = oldBounds;
           
    CGFloat visibleXCenter = CGRectGetMidX(visibleRect);
    NSArray<UICollectionViewLayoutAttributes *> *layoutAttributes = [self layoutAttributesForElementsInRect:visibleRect];
    for (UICollectionViewLayoutAttributes *attributes in layoutAttributes) {
      if ([attributes representedElementCategory] == UICollectionElementCategoryCell && attributes.center.x == visibleXCenter) {
        self.currentIndexPath = attributes.indexPath;
        break;
      }
    }
      
      _didRotate = YES;
    }
    
    [super prepareForAnimatedBoundsChange:oldBounds];
}
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
    // Don't mess around if the user is interacting with the page node. Although if just a rotation happened we should
    // try to use the current index path to not end up setting the target content offset to something in between pages
    if (_didRotate || (!self.collectionView.isDecelerating && !self.collectionView.isTracking)) {
        _didRotate = NO;
        if (self.currentIndexPath) {
            return [self _targetContentOffsetForItemAtIndexPath:self.currentIndexPath proposedContentOffset:proposedContentOffset];
        }
    }
    
    return [super targetContentOffsetForProposedContentOffset:proposedContentOffset];
}

- (CGPoint)_targetContentOffsetForItemAtIndexPath:(NSIndexPath *)indexPath proposedContentOffset:(CGPoint)proposedContentOffset
{
  if ([self _dataSourceIsEmpty]) {
    return proposedContentOffset;
  }
  
  CGFloat currentPageXOffset = self.currentIndexPath.item * CGRectGetWidth(self.collectionView.bounds);
    return CGPointMake(currentPageXOffset, proposedContentOffset.y);
}

- (BOOL)_dataSourceIsEmpty
{
    return ([self.collectionView numberOfSections] == 0 || [self.collectionView numberOfItemsInSection:0] == 0);
}

@end
