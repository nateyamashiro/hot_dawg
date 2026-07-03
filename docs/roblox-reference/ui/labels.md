---
title: "Text & image labels"
url: /docs/en-us/ui/labels
last_updated: 2026-07-02T02:14:46Z
description: "Explore how labels display customizable text and images in user interfaces."
---

# Text & image labels

**Labels** are `Class.GuiObject|GuiObjects` that let you display customizable text and images [on‑screen](/docs/en-us/ui/on-screen-containers.md) or [in‑experience](/docs/en-us/ui/in-experience-containers.md). There are two types of labels:

- A `Class.TextLabel` is a rectangle with text that you can style through customizable properties. This is the primary way to display text in an experience.
- An `Class.ImageLabel` is a rectangle with an image [asset](/docs/en-us/projects/assets.md) that you can style through customizable properties. Alongside [textures and decals](/docs/en-us/parts/textures-decals.md), this lets you display images in an experience.

## Create labels on the screen

Labels on a screen are useful for things like displaying images of characters with dialog.

To add a label to a screen:

1. In the **Explorer** window, select **StarterGui** and add a **ScreenGui**.
  1. Hover over StarterGui and click the ⊕ button. A contextual menu displays.
  2. From the menu, insert a **ScreenGui**.
2. Select the new **ScreenGui** and add a label.
  1. Hover over **ScreenGui** and click the ⊕ button. A contextual menu displays.
  2. From the menu, insert a **TextLabel** or **ImageLabel**.

## Create labels on part faces

Labels on a part are useful for things like creating billboards, posters, and wallpaper.

To add a label to the face of a part:

1. In the **Explorer** window, insert a **SurfaceGui** onto the part.
  1. Hover over the part instance and click the ⊕ button. A contextual menu displays.
  2. From the menu, insert a **SurfaceGui**.
2. Select the new **SurfaceGui** and add a label.
  1. Hover over the **SurfaceGui** and click the ⊕ button. A contextual menu displays.
  2. From the menu, insert a **TextLabel** or **ImageLabel**.
  > **Warning:** If you don't see the button, try [choosing a different face](/docs/en-us/parts/textures-decals.md#choose-a-face) in the **Face** property of the **SurfaceGui**.

## Adjust ImageLabel properties

All images within an `Class.ImageLabel` must be assets that have been [imported](/docs/en-us/projects/assets/manager.md#asset-import) to Studio. While the image automatically scales to fit the area of the rectangle, the image looks best when it displays at its native resolution.

You can customize the visual appearance of an image with the following properties:

- `Class.ImageLabel.ImageColor3|ImageColor3`
- `Class.ImageLabel.ImageTransparency|ImageTransparency`
- `Class.GuiObject.BackgroundTransparency|BackgroundTransparency`

For example, to display only the image and hide the rectangle, set the `Class.GuiObject.BackgroundTransparency|BackgroundTransparency` property to `1`.

## Text filtering

Applied to various sources and inputs, [text filtering](/docs/en-us/ui/text-filtering.md) prevents users from seeing inappropriate language and personally identifiable information such as phone numbers. Roblox automatically filters common text outputs such as messages that have passed through [in-experience text chat](/docs/en-us/chat/in-experience-text-chat.md), but **you are responsible for filtering any displayed text that you don't have explicit control over**, including characters/strings that are displayed on text labels.

> **Error:** Because filtering is crucial for a safe environment, Roblox actively moderates the content of experiences to make sure they meet [community standards](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Community-Standards). If Roblox receives reports or automatically detects that your experience doesn't apply text filtering, then the system removes the experience until you add filtering.